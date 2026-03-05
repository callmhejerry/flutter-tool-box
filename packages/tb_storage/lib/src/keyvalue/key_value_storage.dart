// lib/src/keyvalue/key_value_storage.dart

/// Interface for lightweight key-value storage.
/// Use this for non-sensitive data — flags, preferences, onboarding state.
abstract interface class KeyValueStorage {
  // ── Write ──────────────────────────────────────────────────────────────────
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setStringList(String key, List<String> value);

  // ── Read ───────────────────────────────────────────────────────────────────
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<List<String>?> getStringList(String key);

  // ── Read with defaults ─────────────────────────────────────────────────────
  Future<String> getStringOrDefault(String key, String defaultValue);
  Future<bool> getBoolOrDefault(String key, {required bool defaultValue});
  Future<int> getIntOrDefault(String key, {required int defaultValue});

  // ── Management ─────────────────────────────────────────────────────────────
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<Set<String>> getKeys();
}
