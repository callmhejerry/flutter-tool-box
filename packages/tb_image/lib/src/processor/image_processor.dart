// lib/src/processor/image_processor.dart

import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import '../config/image_config.dart';
import '../models/image_format.dart';
import '../models/image_result.dart';
import 'image_compressor.dart';
import 'image_converter.dart';
import 'image_resizer.dart';

/// Orchestrates the full processing pipeline:
/// crop → compress → resize → convert
///
/// Each step is skipped if its config is null.
class ImageProcessor {
  final _compressor = ImageCompressor();
  final _resizer = ImageResizer();
  final _converter = ImageConverter();

  /// Process a file through the pipeline defined by [config].
  Future<ImageResult> process(File file, ImageProcessConfig config) async {
    var current = file;

    // ── Step 1: Crop ─────────────────────────────────────────────────────────
    if (config.crop != null) {
      current = await _crop(current, config.crop!);
    }

    // ── Step 2: Compress ─────────────────────────────────────────────────────
    if (config.compress != null) {
      current = await _compressor.compress(
        current,
        config.compress!,
        outputFormat: config.convertTo,
      );
    }

    // ── Step 3: Resize ───────────────────────────────────────────────────────
    if (config.resize != null) {
      current = await _resizer.resize(
        current,
        config.resize!,
        outputFormat: config.convertTo,
      );
    }

    // ── Step 4: Convert ──────────────────────────────────────────────────────
    // Skip if already converted during compress/resize step
    if (config.convertTo != null) {
      final currentFormat = ImageFormat.fromExtension(current.path);
      if (currentFormat != config.convertTo) {
        current = await _converter.convert(current, config.convertTo!);
      }
    }

    return _toResult(current);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<File> _crop(File file, CropConfig config) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: config.aspectRatio,
      compressQuality: config.compressQuality,
      uiSettings:
          config.uiSettings ??
          [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              lockAspectRatio: config.lockAspectRatio,
              initAspectRatio: config.aspectRatio != null
                  ? CropAspectRatioPreset.square
                  : CropAspectRatioPreset.original,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: config.lockAspectRatio,
            ),
          ],
    );

    if (cropped == null) {
      // User cancelled the crop — return original
      return file;
    }

    return File(cropped.path);
  }

  Future<ImageResult> _toResult(File file) async {
    final bytes = await file.length();
    return ImageResult(
      file: file,
      sizeInBytes: bytes,
      format: ImageFormat.fromExtension(file.path),
    );
  }
}
