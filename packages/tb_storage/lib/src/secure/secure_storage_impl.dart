// lib/src/secure/secure_storage_impl.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage.dart';

/// [FlutterSecureStorage] backed implementation of [SecureStorage].
///
/// Uses AES encryption on Android and Keychain on iOS.
///
/// ```dart
/// final storage = SecureStorageImpl();
///
/// await storage.write(StorageKeys.accessToken, token);
/// final token = await storage.read(StorageKeys.accessToken);
/// ```
class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorageImpl({AndroidOptions? androidOptions, IOSOptions? iosOptions})
    : _storage = FlutterSecureStorage(
        aOptions: androidOptions ?? AndroidOptions.defaultOptions,
        iOptions:
            iosOptions ??
            const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  @override
  Future<String> readOrThrow(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) {
      throw StateError('tb_storage: SecureStorage key "$key" not found.');
    }
    return value;
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }
}
