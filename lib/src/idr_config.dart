import 'idr_library.dart';

/// Configuration for [IdrClient.open].
class IdrConfig {
  const IdrConfig({
    this.configPath,
    this.apiBaseUrl,
    this.stateDir,
    this.library,
  });

  /// Path to `idr-agent.toml` (optional when [apiBaseUrl] and [stateDir] are set).
  final String? configPath;

  /// Tenant control plane, e.g. `https://idr.to` or `https://sig.scomm.ai`.
  final String? apiBaseUrl;

  /// Writable state directory (device keys, bearer token, certs).
  final String? stateDir;

  /// How to load the native `libidr_sdk` library (defaults to platform names).
  final IdrNativeLibrary? library;
}
