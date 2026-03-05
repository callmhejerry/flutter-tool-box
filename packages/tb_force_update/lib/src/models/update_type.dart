// lib/src/models/update_type.dart

enum UpdateType {
  /// No update available
  none,

  /// Shorebird patch is downloading in the background
  patchDownloading,

  /// Shorebird patch downloaded — app needs restart to apply
  patchReadyToRestart,

  /// Store update available — downloads in background, restart to apply
  flexible,

  /// Critical update — must update before continuing
  immediate,
}
