// lib/src/services/ios_update_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/update_config.dart';
import '../models/update_info.dart';
import '../models/update_type.dart';

/// Handles iOS update checks by calling your backend and
/// comparing the current app version against the server response.
class IosUpdateService {
  final UpdateConfig config;
  final Dio _dio;

  IosUpdateService({required this.config}) : _dio = Dio();

  /// Fetch version info from backend and determine [UpdateType].
  Future<({UpdateType type, UpdateInfo? info})> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get<Map<String, dynamic>>(
        config.versionCheckUrl,
      );

      if (response.data == null) {
        return (type: UpdateType.none, info: null);
      }

      final updateInfo = UpdateInfo.fromJson(response.data!);

      // Force update flag from backend overrides everything
      if (updateInfo.forceUpdate) {
        return (type: UpdateType.immediate, info: updateInfo);
      }

      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(updateInfo.minimumVersion);
      final latest = _parseVersion(updateInfo.latestVersion);

      // Below minimum version → immediate (blocking) update
      if (_isLowerThan(current, minimum)) {
        return (type: UpdateType.immediate, info: updateInfo);
      }

      // Below latest but above minimum → flexible update
      if (_isLowerThan(current, latest)) {
        return (type: UpdateType.flexible, info: updateInfo);
      }

      return (type: UpdateType.none, info: updateInfo);
    } on DioException catch (e) {
      debugPrint('tb_force_update: iOS version check failed — ${e.message}');
      return (type: UpdateType.none, info: null);
    } catch (e) {
      debugPrint('tb_force_update: iOS update check error — $e');
      return (type: UpdateType.none, info: null);
    }
  }

  // ── Version parsing ────────────────────────────────────────────────────────

  List<int> _parseVersion(String version) {
    // Strips build metadata: "1.2.3+45" → "1.2.3"
    final cleaned = version.split('+').first.trim();
    return cleaned.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  bool _isLowerThan(List<int> current, List<int> other) {
    // Pad shorter version with zeros: [1,2] vs [1,2,3] → [1,2,0] vs [1,2,3]
    final length = current.length > other.length
        ? current.length
        : other.length;

    for (int i = 0; i < length; i++) {
      final c = i < current.length ? current[i] : 0;
      final o = i < other.length ? other[i] : 0;

      if (c < o) return true;
      if (c > o) return false;
    }

    return false; // equal
  }
}
