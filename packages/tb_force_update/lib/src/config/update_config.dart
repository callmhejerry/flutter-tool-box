// lib/src/config/update_config.dart

class UpdateConfig {
  final String versionCheckUrl;
  final String iosAppStoreUrl;
  final String androidPackageName;
  final int immediatePriorityThreshold;
  final Duration checkInterval;
  final String dialogTitle;
  final String flexibleDialogMessage;
  final String immediateDialogMessage;
  final bool allowFlexibleDismiss;

  // ── Shorebird ──────────────────────────────────────────────────────────────

  /// Enable Shorebird code push patching.
  /// If true, Shorebird is checked first before Play Store / backend.
  final bool enableShorebird;

  /// If true and a Shorebird patch is available, it downloads silently
  /// without any UI until it is ready to restart.
  final bool silentPatchDownload;

  /// If true, automatically restart the app when a Shorebird patch
  /// finishes downloading — no user prompt needed.
  /// Only recommended for non-critical background patches.
  final bool autoRestartOnPatch;

  /// Message shown in the banner when a Shorebird patch is ready
  final String patchReadyMessage;

  /// Message shown in the banner while a patch is downloading
  final String patchDownloadingMessage;

  const UpdateConfig({
    required this.versionCheckUrl,
    required this.iosAppStoreUrl,
    required this.androidPackageName,
    this.immediatePriorityThreshold = 4,
    this.checkInterval = const Duration(hours: 24),
    this.dialogTitle = 'Update Available',
    this.flexibleDialogMessage =
        'A new version of the app is available. Update now for the latest features and fixes.',
    this.immediateDialogMessage =
        'A critical update is required to continue using the app.',
    this.allowFlexibleDismiss = true,
    // Shorebird defaults
    this.enableShorebird = false,
    this.silentPatchDownload = true,
    this.autoRestartOnPatch = false,
    this.patchReadyMessage =
        'A new update has been applied. Restart to use the latest version.',
    this.patchDownloadingMessage = 'Downloading update in the background...',
  });
}
