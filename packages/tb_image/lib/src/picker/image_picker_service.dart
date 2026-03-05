// lib/src/picker/image_picker_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' as ip;
import 'package:tb_result/tb_result.dart';
import '../config/image_config.dart';
import '../models/image_format.dart';
import '../models/image_result.dart';

/// Handles image picking from all sources.
/// Returns raw files — no processing applied here.
class ImagePickerService {
  final ip.ImagePicker _picker = ip.ImagePicker();

  // ── Single pick ────────────────────────────────────────────────────────────

  /// Pick a single image from the gallery
  Future<Result<ImageResult>> pickFromGallery({
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: ip.ImageSource.gallery,
        maxWidth: config.maxWidth,
        maxHeight: config.maxHeight,
        imageQuality: config.imageQuality,
      );

      if (picked == null) {
        return Result.failure(
          Failure(code: 'CANCELLED', message: 'No image selected.'),
        );
      }

      return Result.success(await _toImageResult(File(picked.path)));
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  /// Pick multiple images from the gallery
  Future<Result<List<ImageResult>>> pickMultipleFromGallery({
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: config.maxWidth,
        maxHeight: config.maxHeight,
        imageQuality: config.imageQuality,
        limit: config.maxFiles,
      );

      if (picked.isEmpty) {
        return Result.failure(
          Failure(code: 'CANCELLED', message: 'No images selected.'),
        );
      }

      final results = await Future.wait(
        picked.map((f) => _toImageResult(File(f.path))),
      );

      return Result.success(results);
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  /// Pick an image from the camera
  Future<Result<ImageResult>> pickFromCamera({
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: ip.ImageSource.camera,
        maxWidth: config.maxWidth,
        maxHeight: config.maxHeight,
        imageQuality: config.imageQuality,
        preferredCameraDevice: config.preferFrontCamera
            ? ip.CameraDevice.front
            : ip.CameraDevice.rear,
      );

      if (picked == null) {
        return Result.failure(
          Failure(code: 'CANCELLED', message: 'Camera cancelled.'),
        );
      }

      return Result.success(await _toImageResult(File(picked.path)));
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  /// Pick an image file using the system file picker
  Future<Result<ImageResult>> pickFile({
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: config.allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return Result.failure(
          Failure(code: 'CANCELLED', message: 'No file selected.'),
        );
      }

      final path = result.files.single.path;
      if (path == null) {
        return Result.failure(
          Failure(code: 'NO_PATH', message: 'Could not get file path.'),
        );
      }

      return Result.success(await _toImageResult(File(path)));
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<ImageResult> _toImageResult(File file) async {
    final bytes = await file.length();
    return ImageResult(
      file: file,
      sizeInBytes: bytes,
      format: ImageFormat.fromExtension(file.path),
    );
  }
}
