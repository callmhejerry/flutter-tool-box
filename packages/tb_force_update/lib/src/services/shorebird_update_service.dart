// lib/src/services/shorebird_update_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../config/update_config.dart';
import '../models/update_type.dart';

/// Handles Shorebird code push patch checks and downloads.
///
/// Checks for patches first — if a patch is available it is much
/// smaller and faster than a full store update.
class ShorebirdUpdateService {
  final UpdateConfig config;
  final _updater = ShorebirdUpdater();

  // Internal stream to notify UpdateService of state changes
  final _stateController = StreamController<UpdateType>.broadcast();
  Stream<UpdateType> get stateStream => _stateController.stream;

  ShorebirdUpdateService({required this.config});

  /// Check if Shorebird is available on this device/build.
  /// Returns false in debug mode or if Shorebird is not integrated.
  bool get isAvailable => _updater.isAvailable;

  /// Check for a patch and optionally download it.
  ///
  /// Returns:
  /// - [UpdateType.patchReadyToRestart] if a patch was already downloaded
  /// - [UpdateType.patchDownloading] if a patch is now downloading
  /// - [UpdateType.none] if no patch available or Shorebird unavailable
  Future<UpdateType> checkForUpdate() async {
    if (!isAvailable) {
      debugPrint('tb_force_update: Shorebird not available on this build.');
      return UpdateType.none;
    }

    try {
      final status = await _updater.checkForUpdate();

      switch (status) {
        // Patch already downloaded in a previous session — ready to restart
        case UpdateStatus.restartRequired:
          debugPrint('tb_force_update: Shorebird patch ready to restart.');
          return UpdateType.patchReadyToRestart;

        // Patch available but not downloaded yet
        case UpdateStatus.outdated:
          debugPrint('tb_force_update: Shorebird patch available.');

          if (config.silentPatchDownload) {
            // Start download in background — don't await
            _downloadPatch();
            return UpdateType.patchDownloading;
          }

          return UpdateType.patchDownloading;

        // Already up to date
        case UpdateStatus.upToDate:
          debugPrint('tb_force_update: Shorebird up to date.');
          return UpdateType.none;
        case UpdateStatus.unavailable:
          return .none;
      }
    } catch (e) {
      debugPrint('tb_force_update: Shorebird check failed — $e');
      return UpdateType.none;
    }
  }

  /// Download the patch in the background.
  /// Emits [UpdateType.patchReadyToRestart] on the stream when done.
  Future<void> _downloadPatch() async {
    try {
      debugPrint('tb_force_update: Downloading Shorebird patch...');

      await _updater.update();

      debugPrint(
        'tb_force_update: Shorebird patch downloaded — restart required.',
      );

      // Notify UpdateService that patch is ready
      _stateController.add(UpdateType.patchReadyToRestart);
    } catch (e) {
      debugPrint('tb_force_update: Shorebird download failed — $e');
      _stateController.add(UpdateType.none);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
