// lib/src/services/update_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '../config/update_config.dart';
import '../models/update_info.dart';
import '../models/update_type.dart';
import 'android_update_service.dart';
import 'ios_update_service.dart';
import 'shorebird_update_service.dart';

class UpdateService {
  final UpdateConfig config;

  late final AndroidUpdateService _android;
  late final IosUpdateService _ios;
  late final ShorebirdUpdateService? _shorebird;

  final _updateTypeController = StreamController<UpdateType>.broadcast();
  final _flexibleReadyController = StreamController<bool>.broadcast();

  UpdateInfo? _lastUpdateInfo;
  DateTime? _lastCheckTime;
  StreamSubscription<InstallStatus>? _installStateSubscription;
  StreamSubscription<UpdateType>? _shorebirdStateSubscription;

  UpdateService({required this.config}) {
    _android = AndroidUpdateService(config: config);
    _ios = IosUpdateService(config: config);

    if (config.enableShorebird) {
      _shorebird = ShorebirdUpdateService(config: config);

      // Listen for patch ready events that arrive after splash
      // (patch finishes downloading while user is already in the app)
      _shorebirdStateSubscription = _shorebird!.stateStream.listen((type) {
        _updateTypeController.add(type);

        // Also signal the banner stream for patchReadyToRestart
        if (type == UpdateType.patchReadyToRestart) {
          _flexibleReadyController.add(true);
        }
      });
    } else {
      _shorebird = null;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Stream<UpdateType> get updateTypeStream => _updateTypeController.stream;

  /// Emits true when any background update (Shorebird patch or
  /// flexible Play Store update) is ready to install.
  Stream<bool> get flexibleUpdateReadyStream => _flexibleReadyController.stream;

  UpdateInfo? get lastUpdateInfo => _lastUpdateInfo;

  /// Fire-and-forget — used from SplashScreen.
  /// Does NOT block rendering.
  void checkOnLaunch() {
    checkForUpdate().catchError((e) {
      debugPrint('tb_force_update: Launch check failed — $e');
      return UpdateType.none;
    });
  }

  /// Full update check with throttling.
  /// Priority: Shorebird → Play Store / Backend
  Future<UpdateType> checkForUpdate({bool force = false}) async {
    // Throttle
    if (!force && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < config.checkInterval) return UpdateType.none;
    }

    _lastCheckTime = DateTime.now();

    // ── 1. Shorebird first (fastest, smallest) ─────────────────────────────
    if (config.enableShorebird && _shorebird != null) {
      final shorebirdType = await _shorebird.checkForUpdate();

      if (shorebirdType != UpdateType.none) {
        _updateTypeController.add(shorebirdType);

        // patchReadyToRestart needs the banner
        if (shorebirdType == UpdateType.patchReadyToRestart) {
          _flexibleReadyController.add(true);
        }

        // If patch is just downloading, still check for
        // major store updates in parallel
        if (shorebirdType == UpdateType.patchDownloading) {
          _checkStoreUpdateInBackground();
        }

        return shorebirdType;
      }
    }

    // ── 2. Fall back to store-based updates ───────────────────────────────
    return _checkStoreUpdate();
  }

  /// Complete a flexible Play Store update (Android only)
  Future<void> completeFlexibleUpdate() async {
    if (Platform.isAndroid) {
      await _android.completeFlexibleUpdate();
    }
  }

  void dispose() {
    _installStateSubscription?.cancel();
    _shorebirdStateSubscription?.cancel();
    _updateTypeController.close();
    _flexibleReadyController.close();
    _shorebird?.dispose();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<UpdateType> _checkStoreUpdate() async {
    UpdateType type;

    if (Platform.isAndroid) {
      type = await _checkAndroid();
    } else if (Platform.isIOS) {
      type = await _checkIos();
    } else {
      return UpdateType.none;
    }

    _updateTypeController.add(type);
    return type;
  }

  /// Check store updates without awaiting — runs alongside Shorebird download
  void _checkStoreUpdateInBackground() {
    _checkStoreUpdate().catchError((e) async {
      debugPrint('tb_force_update: Background store check failed — $e');
      return UpdateType.none;
    });
  }

  Future<UpdateType> _checkAndroid() async {
    final type = await _android.checkForUpdate();

    switch (type) {
      case UpdateType.immediate:
        await _android.startImmediateUpdate();
      case UpdateType.flexible:
        await _android.startFlexibleUpdate();
        _listenToFlexibleInstall();
      default:
        break;
    }

    return type;
  }

  void _listenToFlexibleInstall() {
    _installStateSubscription?.cancel();
    _installStateSubscription = _android.installStateStream.listen((status) {
      if (status == InstallStatus.downloaded) {
        _flexibleReadyController.add(true);
        _updateTypeController.add(UpdateType.flexible);
      }
    });
  }

  Future<UpdateType> _checkIos() async {
    final result = await _ios.checkForUpdate();
    _lastUpdateInfo = result.info;
    return result.type;
  }
}
