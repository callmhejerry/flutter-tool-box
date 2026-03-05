// lib/src/cache/cache_storage.dart

import 'cache_entry.dart';

/// Interface for TTL-based cache storage.
///
/// Use this for API responses, computed data, or anything
/// that should expire after a set duration.
abstract interface class CacheStorage {
  /// Store a value with an optional TTL.
  /// If [ttl] is null the entry never expires.
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// Retrieve a value. Returns null if not found or expired.
  Future<T?> get<T>(String key);

  /// Get the full [CacheEntry] including metadata.
  Future<CacheEntry<T>?> getEntry<T>(String key);

  /// True if key exists AND has not expired.
  Future<bool> has(String key);

  /// True if key exists (even if expired).
  Future<bool> exists(String key);

  /// Delete a single key.
  Future<void> invalidate(String key);

  /// Delete all cache entries.
  Future<void> invalidateAll();

  /// Delete all entries whose keys start with [prefix].
  /// Useful for invalidating a group of related entries.
  ///
  /// ```dart
  /// // Invalidate all user-related cache on logout
  /// await cache.invalidateByPrefix('user:');
  /// ```
  Future<void> invalidateByPrefix(String prefix);

  /// Remove all expired entries to free up storage.
  Future<void> evictExpired();

  /// Returns remaining TTL for a key.
  /// Null if key does not exist or has no expiry.
  Future<Duration?> getRemainingTtl(String key);
}
