import 'dart:ffi';

import 'package:ffi/ffi.dart';

// ignore_for_file: library_private_types_in_public_api

final class IdrConfigStruct extends Struct {
  external Pointer<Utf8> configPath;
  external Pointer<Utf8> apiBaseUrl;
  external Pointer<Utf8> stateDir;
}

final class IdrConnectOptionsStruct extends Struct {
  @Uint32()
  external int holdSeconds;
  @Uint16()
  external int localPort;
  @Uint32()
  external int tunnelTimeoutSeconds;
}

final class IdrAgentProfileStruct extends Struct {
  external Pointer<Utf8> mode;
  external Pointer<Utf8> entityId;
  external Pointer<Utf8> host;
  external Pointer<Utf8> sourceHost;
}

final class IdrJoinOptionsStruct extends Struct {
  external Pointer<Utf8> hostName;
  external Pointer<Utf8> joinKey;
}

final class IdrResultStruct extends Struct {
  @Int32()
  external int ok;
  @Int32()
  external int code;
  external Pointer<Utf8> message;
  external Pointer<Utf8> json;
}

typedef _IdrClientOpenNative = Pointer<Void> Function(Pointer<IdrConfigStruct>);
typedef _IdrClientOpen = Pointer<Void> Function(Pointer<IdrConfigStruct>);

typedef _IdrClientCloseNative = Void Function(Pointer<Void>);
typedef _IdrClientClose = void Function(Pointer<Void>);

typedef _IdrVersionNative = Pointer<Utf8> Function();
typedef _IdrVersion = Pointer<Utf8> Function();

typedef _IdrAuthLoginPasswordNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);
typedef _IdrAuthLoginPassword = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Utf8>,
);

typedef _IdrAuthLoginWithTokenNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
);
typedef _IdrAuthLoginWithToken = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
);

typedef _IdrAuthLogoutNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrAuthLogout = IdrResultStruct Function(Pointer<Void>);

typedef _IdrAuthStatusNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrAuthStatus = IdrResultStruct Function(Pointer<Void>);

typedef _IdrConfigureAgentNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<IdrAgentProfileStruct>,
);
typedef _IdrConfigureAgent = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<IdrAgentProfileStruct>,
);

typedef _IdrConfigSnapshotNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrConfigSnapshot = IdrResultStruct Function(Pointer<Void>);

typedef _IdrDeviceJoinNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<IdrJoinOptionsStruct>,
);
typedef _IdrDeviceJoin = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<IdrJoinOptionsStruct>,
);

typedef _IdrApiHealthNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrApiHealth = IdrResultStruct Function(Pointer<Void>);

typedef _IdrConnectNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Uint16,
);
typedef _IdrConnect = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  int,
);

typedef _IdrConnectExNative = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<IdrConnectOptionsStruct>,
);
typedef _IdrConnectEx = IdrResultStruct Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<IdrConnectOptionsStruct>,
);

typedef _IdrAgentStartNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrAgentStart = IdrResultStruct Function(Pointer<Void>);

typedef _IdrAgentStopNative = IdrResultStruct Function(Pointer<Void>);
typedef _IdrAgentStop = IdrResultStruct Function(Pointer<Void>);

typedef _IdrFreeResultNative = Void Function(Pointer<IdrResultStruct>);
typedef _IdrFreeResult = void Function(Pointer<IdrResultStruct>);

/// Low-level FFI bindings to `libidr_sdk`.
class IdrBindings {
  IdrBindings(DynamicLibrary lib)
      : idrClientOpen =
            lib.lookupFunction<_IdrClientOpenNative, _IdrClientOpen>('idr_client_open'),
        idrClientClose =
            lib.lookupFunction<_IdrClientCloseNative, _IdrClientClose>('idr_client_close'),
        idrVersion = lib.lookupFunction<_IdrVersionNative, _IdrVersion>('idr_version'),
        idrAuthLoginPassword = lib.lookupFunction<_IdrAuthLoginPasswordNative,
            _IdrAuthLoginPassword>('idr_auth_login_password'),
        idrAuthLoginWithToken = lib.lookupFunction<_IdrAuthLoginWithTokenNative,
            _IdrAuthLoginWithToken>('idr_auth_login_with_token'),
        idrAuthLogout =
            lib.lookupFunction<_IdrAuthLogoutNative, _IdrAuthLogout>('idr_auth_logout'),
        idrAuthStatus =
            lib.lookupFunction<_IdrAuthStatusNative, _IdrAuthStatus>('idr_auth_status'),
        idrConfigureAgent = lib.lookupFunction<_IdrConfigureAgentNative, _IdrConfigureAgent>(
            'idr_configure_agent'),
        idrConfigSnapshot = lib.lookupFunction<_IdrConfigSnapshotNative, _IdrConfigSnapshot>(
            'idr_config_snapshot'),
        idrDeviceJoin =
            lib.lookupFunction<_IdrDeviceJoinNative, _IdrDeviceJoin>('idr_device_join'),
        idrApiHealth =
            lib.lookupFunction<_IdrApiHealthNative, _IdrApiHealth>('idr_api_health'),
        idrConnect =
            lib.lookupFunction<_IdrConnectNative, _IdrConnect>('idr_connect'),
        idrConnectEx = _tryLookupConnectEx(lib),
        idrAgentStart =
            lib.lookupFunction<_IdrAgentStartNative, _IdrAgentStart>('idr_agent_start'),
        idrAgentStop =
            lib.lookupFunction<_IdrAgentStopNative, _IdrAgentStop>('idr_agent_stop'),
        idrFreeResult =
            lib.lookupFunction<_IdrFreeResultNative, _IdrFreeResult>('idr_free_result');

  final _IdrClientOpen idrClientOpen;
  final _IdrClientClose idrClientClose;
  final _IdrVersion idrVersion;
  final _IdrAuthLoginPassword idrAuthLoginPassword;
  final _IdrAuthLoginWithToken idrAuthLoginWithToken;
  final _IdrAuthLogout idrAuthLogout;
  final _IdrAuthStatus idrAuthStatus;
  final _IdrConfigureAgent idrConfigureAgent;
  final _IdrConfigSnapshot idrConfigSnapshot;
  final _IdrDeviceJoin idrDeviceJoin;
  final _IdrApiHealth idrApiHealth;
  final _IdrConnect idrConnect;
  final _IdrConnectEx? idrConnectEx;
  final _IdrAgentStart idrAgentStart;
  final _IdrAgentStop idrAgentStop;
  final _IdrFreeResult idrFreeResult;

  static _IdrConnectEx? _tryLookupConnectEx(DynamicLibrary lib) {
    try {
      return lib.lookupFunction<_IdrConnectExNative, _IdrConnectEx>('idr_connect_ex');
    } on ArgumentError {
      return null;
    }
  }
}
