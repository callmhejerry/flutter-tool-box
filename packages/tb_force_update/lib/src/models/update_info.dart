// lib/src/models/update_info.dart

/// Version info returned by your backend (iOS) or computed from
/// Play Store data (Android).
///
/// Expected backend response shape:
/// ```json
/// {
///   "latest_version": "2.1.0",
///   "minimum_version": "1.5.0",
///   "release_notes": "Bug fixes and performance improvements.",
///   "force_update": false
/// }
/// ```
class UpdateInfo {
  /// The latest available version
  final String latestVersion;

  /// The minimum supported version — anything below triggers immediate update
  final String minimumVersion;

  /// Human-readable release notes shown in the update dialog
  final String? releaseNotes;

  /// If true, always treat as immediate regardless of version comparison
  final bool forceUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.minimumVersion,
    this.releaseNotes,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
    latestVersion: json['latest_version'] as String,
    minimumVersion: json['minimum_version'] as String,
    releaseNotes: json['release_notes'] as String?,
    forceUpdate: json['force_update'] as bool? ?? false,
  );
}
