import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and persists the SQLCipher passphrase (NFR-SEC-002).
///
/// Deliberately separate from [AppDatabase]/[openEncryptedExecutor]: the
/// database takes a plain key string and never touches
/// flutter_secure_storage itself, so tests can supply a fixed key without
/// mocking a platform channel. This class is the only thing that talks to
/// secure storage, and only production code (`main.dart`) calls it.
class DatabaseKeyProvider {
  const DatabaseKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _storageKey = 'aagahi.db_encryption_key';

  /// Returns the existing key, or generates, persists, and returns a new
  /// 256-bit key on first run.
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generated =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _storage.write(key: _storageKey, value: generated);
    return generated;
  }
}
