// lib/src/secure/secure_storage.dart

/// Interface for secure encrypted storage.
/// Use this for sensitive data — auth tokens, refresh tokens, PINs.
///
/// Code against this interface, not the implementation,
/// so you can swap the underlying storage in tests.
abstract interface class SecureStorage {
  /// Write a value. Overwrites if key already exists.
  Future<void> write(String key, String value);

  /// Read a value. Returns null if key does not exist.
  Future<String?> read(String key);

  /// Read a value or throw if it does not exist.
  Future<String> readOrThrow(String key);

  /// Delete a single key.
  Future<void> delete(String key);

  /// Delete all keys written by this app.
  Future<void> deleteAll();

  /// Check if a key exists.
  Future<bool> containsKey(String key);

  /// Read all key-value pairs.
  Future<Map<String, String>> readAll();
}
