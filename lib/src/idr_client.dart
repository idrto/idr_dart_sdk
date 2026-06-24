import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'idr_agent_profile.dart';
import 'idr_bindings.dart';
import 'idr_config.dart';
import 'idr_connect_options.dart';
import 'idr_event.dart';
import 'idr_join_options.dart';
import 'idr_library.dart';
import 'idr_result.dart';
import 'idr_session.dart';
import 'idr_token_storage.dart';

/// Programmatic idr.to client for Dart embedders (CLI, server, Flutter app, etc.).
class IdrClient {
  IdrClient._(this._bindings, this._handle, this._tokenStorage);

  static IdrBindings? _loadedBindings;

  final IdrBindings _bindings;
  final Pointer<Void> _handle;
  final IdrTokenStorage _tokenStorage;
  final _eventController = StreamController<IdrEvent>.broadcast();

  Stream<IdrEvent> get events => _eventController.stream;

  static Future<IdrClient> open(
    IdrConfig config, {
    IdrTokenStorage tokenStorage = const NoOpIdrTokenStorage(),
  }) async {
    final library = config.library ?? const DefaultIdrNativeLibrary();
    final bindings = _loadedBindings ??= IdrBindings(library.open());

    final nativeConfig = calloc<IdrConfigStruct>();
    final configPathPtr = _optionalUtf8(config.configPath);
    final apiBaseUrlPtr = _optionalUtf8(config.apiBaseUrl);
    final stateDirPtr = _optionalUtf8(config.stateDir);
    try {
      nativeConfig.ref.configPath = configPathPtr ?? nullptr;
      nativeConfig.ref.apiBaseUrl = apiBaseUrlPtr ?? nullptr;
      nativeConfig.ref.stateDir = stateDirPtr ?? nullptr;

      final handle = bindings.idrClientOpen(nativeConfig);
      if (handle == nullptr) {
        throw StateError(
          'idr_client_open failed — check config, stateDir, and libidr_sdk',
        );
      }
      return IdrClient._(bindings, handle, tokenStorage);
    } finally {
      calloc.free(nativeConfig);
      if (configPathPtr != null) calloc.free(configPathPtr);
      if (apiBaseUrlPtr != null) calloc.free(apiBaseUrlPtr);
      if (stateDirPtr != null) calloc.free(stateDirPtr);
    }
  }

  static Pointer<Utf8>? _optionalUtf8(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.toNativeUtf8().cast();
  }

  String get version => _bindings.idrVersion().cast<Utf8>().toDartString();

  Future<IdrResult> configureAgent(IdrAgentProfile profile) async {
    final native = calloc<IdrAgentProfileStruct>();
    final modePtr = profile.mode.value.toNativeUtf8().cast<Utf8>();
    final entityPtr = profile.entityId.toNativeUtf8().cast<Utf8>();
    final hostPtr = profile.host.toNativeUtf8().cast<Utf8>();
    final sourcePtr = _optionalUtf8(profile.sourceHost);
    try {
      native.ref.mode = modePtr;
      native.ref.entityId = entityPtr;
      native.ref.host = hostPtr;
      native.ref.sourceHost = sourcePtr ?? nullptr;
      return _parseResult(_bindings.idrConfigureAgent(_handle, native));
    } finally {
      calloc.free(native);
      calloc.free(modePtr);
      calloc.free(entityPtr);
      calloc.free(hostPtr);
      if (sourcePtr != null) calloc.free(sourcePtr);
    }
  }

  Future<IdrResult> getConfig() async {
    return _parseResult(_bindings.idrConfigSnapshot(_handle));
  }

  Future<void> loginWithPassword({
    required String entityId,
    required String password,
  }) async {
    final entityPtr = entityId.toNativeUtf8().cast<Utf8>();
    final passwordPtr = password.toNativeUtf8().cast<Utf8>();
    try {
      final result = _bindings.idrAuthLoginPassword(
        _handle,
        entityPtr,
        passwordPtr,
      );
      await _applyAuthResult(result, entityId: entityId);
    } finally {
      calloc.free(entityPtr);
      calloc.free(passwordPtr);
    }
  }

  Future<void> loginWithToken(String token) async {
    final tokenPtr = token.toNativeUtf8().cast<Utf8>();
    try {
      final result = _bindings.idrAuthLoginWithToken(_handle, tokenPtr);
      await _applyAuthResult(result);
    } finally {
      calloc.free(tokenPtr);
    }
  }

  Future<void> logout() async {
    final result = _bindings.idrAuthLogout(_handle);
    _throwOnError(result);
    await _tokenStorage.delete(_tokenKey);
    await _tokenStorage.delete(_entityKey);
  }

  Future<IdrResult> authStatus() async {
    return _parseResult(_bindings.idrAuthStatus(_handle));
  }

  Future<IdrResult> joinDevice(IdrJoinOptions options) async {
    final native = calloc<IdrJoinOptionsStruct>();
    final hostPtr = options.hostName.toNativeUtf8().cast<Utf8>();
    final keyPtr = _optionalUtf8(options.joinKey);
    try {
      native.ref.hostName = hostPtr;
      native.ref.joinKey = keyPtr ?? nullptr;
      final parsed = _parseResult(_bindings.idrDeviceJoin(_handle, native));
      if (parsed.ok && parsed.data['status'] == 'pending') {
        _eventController.add(IdrJoinPendingEvent(
          requestId: parsed.data['id']?.toString() ?? '',
          host: options.hostName,
        ));
      }
      return parsed;
    } finally {
      calloc.free(native);
      calloc.free(hostPtr);
      if (keyPtr != null) calloc.free(keyPtr);
    }
  }

  Future<IdrResult> apiHealth() async {
    return _parseResult(_bindings.idrApiHealth(_handle));
  }

  Future<IdrSession> connect(
    String idrtoUri, {
    IdrConnectOptions options = const IdrConnectOptions(),
  }) async {
    final uriPtr = idrtoUri.toNativeUtf8().cast<Utf8>();
    try {
      final IdrResultStruct native;
      final connectEx = _bindings.idrConnectEx;
      if (connectEx != null) {
        final opts = calloc<IdrConnectOptionsStruct>();
        try {
          opts.ref.holdSeconds = options.holdSeconds;
          opts.ref.localPort = options.localPort;
          opts.ref.tunnelTimeoutSeconds = options.tunnelTimeoutSeconds;
          native = connectEx(_handle, uriPtr, opts);
        } finally {
          calloc.free(opts);
        }
      } else {
        native = _bindings.idrConnect(_handle, uriPtr, options.localPort);
      }
      final parsed = _parseResult(native);
      if (!parsed.ok) {
        throw StateError(parsed.message ?? 'connect failed');
      }
      _eventController.add(
        IdrConnectionStateEvent(state: 'connected:${parsed.data['signal_session']}'),
      );
      return IdrSession.fromJson(parsed.data);
    } finally {
      calloc.free(uriPtr);
    }
  }

  Future<void> startAgent() async {
    final result = _bindings.idrAgentStart(_handle);
    _throwOnError(result);
    _eventController.add(const IdrConnectionStateEvent(state: 'agent_started'));
  }

  Future<void> stopAgent() async {
    final result = _bindings.idrAgentStop(_handle);
    _throwOnError(result);
    _eventController.add(const IdrConnectionStateEvent(state: 'agent_stopped'));
  }

  void dispose() {
    _bindings.idrClientClose(_handle);
    _eventController.close();
  }

  static const _tokenKey = 'idr_bearer_token';
  static const _entityKey = 'idr_entity_id';

  Future<void> _applyAuthResult(
    IdrResultStruct result, {
    String? entityId,
  }) async {
    final parsed = _parseResult(result);
    if (!parsed.ok) throw StateError(parsed.message ?? 'login failed');
    final token = parsed.data['token'] as String?;
    if (token != null) {
      await _tokenStorage.write(_tokenKey, token);
    }
    if (entityId != null) {
      await _tokenStorage.write(_entityKey, entityId);
    }
  }

  IdrResult _parseResult(IdrResultStruct native) {
    final ok = native.ok != 0;
    final code = native.code;
    final message =
        native.message == nullptr ? null : native.message.cast<Utf8>().toDartString();
    var data = const <String, dynamic>{};
    if (native.json != nullptr) {
      final text = native.json.cast<Utf8>().toDartString();
      if (text.isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      }
    }
    final ptr = calloc<IdrResultStruct>()..ref = native;
    _bindings.idrFreeResult(ptr);
    calloc.free(ptr);
    return IdrResult(ok: ok, code: code, message: message, data: data);
  }

  void _throwOnError(IdrResultStruct native) {
    final parsed = _parseResult(native);
    if (!parsed.ok) {
      throw StateError(parsed.message ?? 'idr_sdk error ${parsed.code}');
    }
  }
}
