// lib/src/cache/cache_entry.dart

import 'dart:convert';

/// Wraps a cached value with expiry metadata.
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const CacheEntry({
    required this.value,
    required this.createdAt,
    this.expiresAt,
  });

  /// True if this entry has passed its TTL
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// True if this entry is still valid
  bool get isValid => !isExpired;

  /// Remaining TTL — null if no expiry set
  Duration? get remainingTtl {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ── Serialization ──────────────────────────────────────────────────────────
  // CacheStorage stores everything as JSON strings in SharedPreferences.
  // T must be a JSON-encodable type (String, num, bool, Map, List).

  Map<String, dynamic> toJson() => {
    'value': value,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
  };

  static CacheEntry<T> fromJson<T>(Map<String, dynamic> json) => CacheEntry<T>(
    value: json['value'] as T,
    createdAt: DateTime.parse(json['created_at'] as String),
    expiresAt: json['expires_at'] != null
        ? DateTime.parse(json['expires_at'] as String)
        : null,
  );

  static CacheEntry<T>? tryFromJsonString<T>(String? jsonString) {
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry.fromJson<T>(map);
    } catch (_) {
      return null;
    }
  }

  String toJsonString() => jsonEncode(toJson());
}
