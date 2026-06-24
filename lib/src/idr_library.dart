import 'dart:ffi';
import 'dart:io';

/// Opens the native `libidr_sdk` shared library for FFI.
abstract interface class IdrNativeLibrary {
  DynamicLibrary open();
}

/// Platform-default library names, with optional [libraryPath] override.
class DefaultIdrNativeLibrary implements IdrNativeLibrary {
  const DefaultIdrNativeLibrary({this.libraryPath});

  /// Absolute path to `libidr_sdk.so`, `idr_sdk.dll`, etc.
  final String? libraryPath;

  @override
  DynamicLibrary open() {
    if (libraryPath != null && libraryPath!.isNotEmpty) {
      return DynamicLibrary.open(libraryPath!);
    }
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libidr_sdk.so');
    }
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libidr_sdk.dylib');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('libidr_sdk.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('idr_sdk.dll');
    }
    throw UnsupportedError('Unsupported platform for libidr_sdk');
  }
}
