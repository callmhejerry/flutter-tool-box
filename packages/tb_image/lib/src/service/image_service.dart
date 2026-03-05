// lib/src/service/image_service.dart

import 'dart:io';
import 'package:tb_result/tb_result.dart';
import '../config/image_config.dart';
import '../models/image_result.dart';
import '../picker/image_picker_service.dart';
import '../processor/image_processor.dart';

/// Main facade — combines picking and processing in one call.
///
/// ```dart
/// final imageService = ImageService();
///
/// // Pick from gallery and process as avatar
/// final result = await imageService.pickAndProcess(
///   source: ImageSource.gallery,
///   processConfig: ImageProcessConfig.avatarUpload,
/// );
///
/// result.when(
///   success: (image) => uploadAvatar(image.file),
///   failure: (f) => showError(f.message),
/// );
/// ```
class ImageService {
  final _picker = ImagePickerService();
  final _processor = ImageProcessor();

  // ── Pick + Process ─────────────────────────────────────────────────────────

  /// Pick a single image from [source] and optionally process it.
  Future<Result<ImageResult>> pickAndProcess({
    required ImageSource source,
    ImagePickerConfig pickerConfig = const ImagePickerConfig(),
    ImageProcessConfig? processConfig,
  }) async {
    // Step 1: Pick
    final pickResult = await _pickFromSource(source, pickerConfig);

    if (pickResult.isFailure) return pickResult;

    // Step 2: Process (optional)
    if (processConfig == null) return pickResult;

    return _processResult(pickResult.dataOrNull!, processConfig);
  }

  /// Pick multiple images from gallery and optionally process each one.
  Future<Result<List<ImageResult>>> pickMultipleAndProcess({
    ImagePickerConfig pickerConfig = const ImagePickerConfig(),
    ImageProcessConfig? processConfig,
  }) async {
    final pickResult = await _picker.pickMultipleFromGallery(
      config: pickerConfig,
    );

    if (pickResult.isFailure) {
      return Result.failure(pickResult.failureOrNull!);
    }

    if (processConfig == null) return pickResult;

    // Process all images in parallel
    try {
      final processed = await Future.wait(
        pickResult.dataOrNull!.map(
          (image) => _processor.process(image.file, processConfig),
        ),
      );
      return Result.success(processed);
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  // ── Process only ───────────────────────────────────────────────────────────

  /// Process an existing [File] through the pipeline.
  Future<Result<ImageResult>> processFile(
    File file,
    ImageProcessConfig config,
  ) async {
    try {
      final result = await _processor.process(file, config);
      return Result.success(result);
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }

  // ── Pick only ──────────────────────────────────────────────────────────────

  /// Pick without any processing.
  Future<Result<ImageResult>> pick(
    ImageSource source, {
    ImagePickerConfig config = const ImagePickerConfig(),
  }) => _pickFromSource(source, config);

  /// Pick multiple without processing.
  Future<Result<List<ImageResult>>> pickMultiple({
    ImagePickerConfig config = const ImagePickerConfig(),
  }) => _picker.pickMultipleFromGallery(config: config);

  // ── Private ────────────────────────────────────────────────────────────────

  Future<Result<ImageResult>> _pickFromSource(
    ImageSource source,
    ImagePickerConfig config,
  ) => switch (source) {
    ImageSource.gallery => _picker.pickFromGallery(config: config),
    ImageSource.camera => _picker.pickFromCamera(config: config),
    ImageSource.file => _picker.pickFile(config: config),
  };

  Future<Result<ImageResult>> _processResult(
    ImageResult image,
    ImageProcessConfig config,
  ) async {
    try {
      final processed = await _processor.process(image.file, config);
      return Result.success(processed);
    } catch (e, st) {
      return Result.failure(
        Failure.unexpected(originalError: e, stackTrace: st),
      );
    }
  }
}
