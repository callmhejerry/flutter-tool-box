// lib/src/keyvalue/key_value_storage_impl.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'key_value_storage.dart';

/// [SharedPreferences] backed implementation of [KeyValueStorage].
///
/// ```dart
/// final prefs = await KeyValueStorageImpl.create();
///
/// await prefs.setBool(StorageKeys.hasSeenOnboarding, true);
/// final seen = await prefs.getBoolOrDefault(
///   StorageKeys.hasSeenOnboarding,
///   defaultValue: false,
/// );
/// ```
class KeyValueStorageImpl implements KeyValueStorage {
  final SharedPreferences _prefs;

  /// Private constructor — use [create] factory
  KeyValueStorageImpl._(this._prefs);

  /// Async factory — call this once and inject the result
  static Future<KeyValueStorageImpl> create() async {
    final prefs = await SharedPreferences.getInstance();
    return KeyValueStorageImpl._(prefs);
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<List<String>?> getStringList(String key) async =>
      _prefs.getStringList(key);

  // ── Read with defaults ─────────────────────────────────────────────────────

  @override
  Future<String> getStringOrDefault(String key, String defaultValue) async =>
      _prefs.getString(key) ?? defaultValue;

  @override
  Future<bool> getBoolOrDefault(
    String key, {
    required bool defaultValue,
  }) async => _prefs.getBool(key) ?? defaultValue;

  @override
  Future<int> getIntOrDefault(String key, {required int defaultValue}) async =>
      _prefs.getInt(key) ?? defaultValue;

  // ── Management ─────────────────────────────────────────────────────────────

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);

  @override
  Future<void> clear() async => _prefs.clear();

  @override
  Future<Set<String>> getKeys() async => _prefs.getKeys();
}
