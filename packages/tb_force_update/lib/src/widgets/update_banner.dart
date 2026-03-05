// lib/src/widgets/update_banner.dart

import 'package:flutter/material.dart';
import '../models/update_type.dart';
import '../services/update_service.dart';

class UpdateBanner extends StatefulWidget {
  final UpdateService service;
  final String? restartLabel;
  final String? dismissLabel;
  final Color? backgroundColor;

  const UpdateBanner({
    super.key,
    required this.service,
    this.restartLabel,
    this.dismissLabel = 'Later',
    this.backgroundColor,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  bool _isDownloading = false; // true while patch is downloading
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Show downloading indicator while patch downloads
    widget.service.updateTypeStream.listen((type) {
      if (!mounted) return;

      if (type == UpdateType.patchDownloading) {
        setState(() {
          _isVisible = true;
          _isDownloading = true;
        });
        _animController.forward();
      }

      if (type == UpdateType.patchReadyToRestart) {
        setState(() {
          _isVisible = true;
          _isDownloading = false;
        });
        _animController.forward();
      }
    });

    // Also listen to flexible ready stream (Play Store flexible)
    widget.service.flexibleUpdateReadyStream.listen((ready) {
      if (ready && mounted) {
        setState(() {
          _isVisible = true;
          _isDownloading = false;
        });
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Future<void> _onRestart() async {
  //   // Shorebird restart or Play Store flexible complete
  //   await widget.service.restartForPatch();
  //   await widget.service.completeFlexibleUpdate();
  // }

  Future<void> _onDismiss() async {
    await _animController.reverse();
    if (mounted) setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final config = widget.service.config;
    final bgColor =
        widget.backgroundColor ?? theme.colorScheme.primaryContainer;

    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 8,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: bgColor,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Spinner while downloading, icon when ready
                _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt_rounded, size: 20),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _isDownloading
                        ? config.patchDownloadingMessage
                        : config.patchReadyMessage,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),

                // No action buttons while downloading
                if (!_isDownloading) ...[
                  if (widget.dismissLabel != null)
                    TextButton(
                      onPressed: _onDismiss,
                      child: Text(widget.dismissLabel!),
                    ),
                  // const SizedBox(width: 4),
                  // FilledButton.tonal(
                  //   onPressed: _onRestart,
                  //   child: Text(widget.restartLabel ?? 'Restart'),
                  // ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
