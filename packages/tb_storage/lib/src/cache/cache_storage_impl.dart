// lib/src/cache/cache_storage_impl.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'cache_entry.dart';
import 'cache_storage.dart';

/// [SharedPreferences] backed [CacheStorage] with TTL support.
///
/// All values are JSON-encoded and stored with expiry metadata.
/// Only supports JSON-encodable types: String, num, bool, Map, List.
///
/// ```dart
/// final cache = await CacheStorageImpl.create();
///
/// // Cache API response for 10 minutes
/// await cache.set('user:123', userJson, ttl: Duration(minutes: 10));
///
/// // Read — returns null if expired or missing
/// final data = await cache.get<Map<String, dynamic>>('user:123');
///
/// // Invalidate all user entries on logout
/// await cache.invalidateByPrefix('user:');
/// ```
class CacheStorageImpl implements CacheStorage {
  final SharedPreferences _prefs;

  /// Prefix all cache keys to avoid collision with KeyValueStorage
  static const _keyPrefix = 'tb_cache:';

  CacheStorageImpl._(this._prefs);

  static Future<CacheStorageImpl> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CacheStorageImpl._(prefs);
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final entry = CacheEntry<T>(
      value: value,
      createdAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );

    await _prefs.setString(_prefixed(key), entry.toJsonString());
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  @override
  Future<T?> get<T>(String key) async {
    final entry = await getEntry<T>(key);
    return entry?.value;
  }

  @override
  Future<CacheEntry<T>?> getEntry<T>(String key) async {
    final jsonString = _prefs.getString(_prefixed(key));
    final entry = CacheEntry.tryFromJsonString<T>(jsonString);

    if (entry == null) return null;

    // Auto-evict expired entries on read
    if (entry.isExpired) {
      await invalidate(key);
      return null;
    }

    return entry;
  }

  // ── Checks ─────────────────────────────────────────────────────────────────

  @override
  Future<bool> has(String key) async {
    final entry = await getEntry(key);
    return entry != null;
  }

  @override
  Future<bool> exists(String key) async {
    return _prefs.containsKey(_prefixed(key));
  }

  @override
  Future<Duration?> getRemainingTtl(String key) async {
    final entry = await getEntry(key);
    return entry?.remainingTtl;
  }

  // ── Invalidation ───────────────────────────────────────────────────────────

  @override
  Future<void> invalidate(String key) async {
    await _prefs.remove(_prefixed(key));
  }

  @override
  Future<void> invalidateAll() async {
    final cacheKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();

    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }

  @override
  Future<void> invalidateByPrefix(String prefix) async {
    final fullPrefix = _prefixed(prefix);
    final matchingKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith(fullPrefix))
        .toList();

    for (final key in matchingKeys) {
      await _prefs.remove(key);
    }
  }

  @override
  Future<void> evictExpired() async {
    final cacheKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();

    for (final key in cacheKeys) {
      final jsonString = _prefs.getString(key);
      final entry = CacheEntry.tryFromJsonString(jsonString);
      if (entry != null && entry.isExpired) {
        await _prefs.remove(key);
      }
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  String _prefixed(String key) => '$_keyPrefix$key';
}
