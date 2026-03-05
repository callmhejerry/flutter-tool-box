// lib/src/services/android_update_service.dart

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '../models/update_type.dart';
import '../config/update_config.dart';

/// Handles Android in-app updates via the Google Play Core API.
///
/// Two flows:
/// - Flexible: download in background → notify when ready → user restarts
/// - Immediate: full-screen blocking update flow
class AndroidUpdateService {
  final UpdateConfig config;

  AndroidUpdateService({required this.config});

  /// Check Play Store for available update.
  /// Returns the [UpdateType] based on update availability and priority.
  Future<UpdateType> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return UpdateType.none;
      }

      // Play Store assigns priority 0–5 to each release via the Play Console.
      // Priority >= threshold → immediate, otherwise flexible.
      final priority = info.updatePriority;

      if (priority >= config.immediatePriorityThreshold) {
        return UpdateType.immediate;
      }

      return UpdateType.flexible;
    } catch (e) {
      debugPrint('tb_force_update: Android update check failed — $e');
      return UpdateType.none;
    }
  }

  /// Start the flexible update flow.
  ///
  /// The update downloads in the background. Listen to
  /// [installStateStream] to know when it is ready to install.
  Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      debugPrint('tb_force_update: Flexible update start failed — $e');
    }
  }

  /// Start the immediate update flow.
  ///
  /// Shows a full-screen, non-dismissible system UI.
  /// The app resumes automatically after the update installs.
  Future<void> startImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('tb_force_update: Immediate update failed — $e');
    }
  }

  /// Call this when the flexible update has finished downloading
  /// and the user confirms they want to restart.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('tb_force_update: Complete flexible update failed — $e');
    }
  }

  /// Stream of install state changes during a flexible update.
  ///
  /// Emits [InstallStatus.downloaded] when the update is ready to install.
  Stream<InstallStatus> get installStateStream =>
      InAppUpdate.installUpdateListener.map((state) => state);
}
