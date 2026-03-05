// lib/src/widgets/update_dialog.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/update_config.dart';
import '../models/update_type.dart';

/// A dialog shown on iOS (and Android fallback) when an update is available.
///
/// - [UpdateType.immediate] → non-dismissible, no "Later" button
/// - [UpdateType.flexible]  → dismissible if [UpdateConfig.allowFlexibleDismiss]
///
/// ```dart
/// // Show from your update stream listener
/// updateService.updateTypeStream.listen((type) {
///   if (type != UpdateType.none && Platform.isIOS) {
///     showUpdateDialog(
///       context: context,
///       type: type,
///       config: updateConfig,
///       releaseNotes: updateService.lastUpdateInfo?.releaseNotes,
///     );
///   }
/// });
/// ```
Future<void> showUpdateDialog({
  required BuildContext context,
  required UpdateType type,
  required UpdateConfig config,
  String? releaseNotes,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        UpdateDialog(type: type, config: config, releaseNotes: releaseNotes),
  );
}

class UpdateDialog extends StatelessWidget {
  final UpdateType type;
  final UpdateConfig config;
  final String? releaseNotes;

  const UpdateDialog({
    super.key,
    required this.type,
    required this.config,
    this.releaseNotes,
  });

  bool get _isImmediate => type == UpdateType.immediate;

  Future<void> _openStore() async {
    final uri = Uri.parse(config.iosAppStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Prevent back button dismissal on immediate updates
      canPop: !_isImmediate,
      child: AlertDialog(
        icon: const Icon(Icons.system_update_rounded, size: 40),
        title: Text(config.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isImmediate
                  ? config.immediateDialogMessage
                  : config.flexibleDialogMessage,
            ),
            if (releaseNotes != null && releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text("What's new", style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(releaseNotes!, style: theme.textTheme.bodySmall),
              ),
            ],
          ],
        ),
        actions: [
          // "Later" only shown for flexible updates when dismissal is allowed
          if (!_isImmediate && config.allowFlexibleDismiss)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          FilledButton(onPressed: _openStore, child: const Text('Update Now')),
        ],
      ),
    );
  }
}
