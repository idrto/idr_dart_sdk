import 'dart:io';

/// Optional cache for login metadata in the embedder process.
///
/// Bearer tokens are persisted by the Rust agent under [IdrConfig.stateDir];
/// this interface is for apps that also want a Dart-side copy (e.g. UI state).
abstract interface class IdrTokenStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

/// Default: no Dart-side token cache (Rust state dir is authoritative).
class NoOpIdrTokenStorage implements IdrTokenStorage {
  const NoOpIdrTokenStorage();

  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

/// File-backed storage under a directory.
class FileIdrTokenStorage implements IdrTokenStorage {
  FileIdrTokenStorage(this.directory);

  final String directory;

  @override
  Future<void> delete(String key) async {
    final file = _fileFor(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<String?> read(String key) async {
    final file = _fileFor(key);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String key, String value) async {
    final file = _fileFor(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  File _fileFor(String key) =>
      File('$directory/${key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.txt');
}
