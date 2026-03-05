// lib/src/config/image_config.dart

import 'package:image_cropper/image_cropper.dart';
import '../models/image_format.dart';

/// Source to pick an image from
enum ImageSource { gallery, camera, file }

/// Aspect ratio presets for cropping
enum CropRatio {
  free,
  square, // 1:1
  portrait, // 3:4
  landscape, // 4:3
  widescreen, // 16:9
  custom, // use customRatioX + customRatioY
}

/// Config for the crop step
class CropConfig {
  final CropRatio ratio;
  final double? customRatioX;
  final double? customRatioY;
  final bool lockAspectRatio;
  final int compressQuality;

  /// UI appearance
  final List<PlatformUiSettings>? uiSettings;

  const CropConfig({
    this.ratio = CropRatio.free,
    this.customRatioX,
    this.customRatioY,
    this.lockAspectRatio = false,
    this.compressQuality = 90,
    this.uiSettings,
  });

  // Convenience presets
  static const square = CropConfig(
    ratio: CropRatio.square,
    lockAspectRatio: true,
  );

  static const avatar = CropConfig(
    ratio: CropRatio.square,
    lockAspectRatio: true,
    compressQuality: 85,
  );

  static const banner = CropConfig(
    ratio: CropRatio.widescreen,
    lockAspectRatio: true,
  );

  CropAspectRatio? get aspectRatio => switch (ratio) {
    CropRatio.free => null,
    CropRatio.square => const CropAspectRatio(ratioX: 1, ratioY: 1),
    CropRatio.portrait => const CropAspectRatio(ratioX: 3, ratioY: 4),
    CropRatio.landscape => const CropAspectRatio(ratioX: 4, ratioY: 3),
    CropRatio.widescreen => const CropAspectRatio(ratioX: 16, ratioY: 9),
    CropRatio.custom =>
      customRatioX != null && customRatioY != null
          ? CropAspectRatio(ratioX: customRatioX!, ratioY: customRatioY!)
          : null,
  };
}

/// Config for the compress step
class CompressConfig {
  /// Output quality 0–100
  final int quality;

  /// Cap the output width — maintains aspect ratio if height not set
  final int? maxWidth;

  /// Cap the output height — maintains aspect ratio if width not set
  final int? maxHeight;

  const CompressConfig({this.quality = 85, this.maxWidth, this.maxHeight});

  // Presets
  static const thumbnail = CompressConfig(
    quality: 70,
    maxWidth: 300,
    maxHeight: 300,
  );

  static const medium = CompressConfig(
    quality: 80,
    maxWidth: 800,
    maxHeight: 800,
  );

  static const high = CompressConfig(
    quality: 90,
    maxWidth: 1920,
    maxHeight: 1080,
  );
}

/// Config for the resize step
class ResizeConfig {
  final int width;
  final int height;
  final bool maintainAspectRatio;

  const ResizeConfig({
    required this.width,
    required this.height,
    this.maintainAspectRatio = true,
  });
}

/// Full processing pipeline config.
/// Set a step to null to skip it.
class ImageProcessConfig {
  /// Crop step — null = skip
  final CropConfig? crop;

  /// Compress step — null = skip
  final CompressConfig? compress;

  /// Resize step — null = skip
  final ResizeConfig? resize;

  /// Convert to a different format — null = keep original
  final ImageFormat? convertTo;

  const ImageProcessConfig({
    this.crop,
    this.compress,
    this.resize,
    this.convertTo,
  });

  // Common presets
  static const avatarUpload = ImageProcessConfig(
    crop: CropConfig.avatar,
    compress: CompressConfig.medium,
    convertTo: ImageFormat.jpg,
  );

  static const bannerUpload = ImageProcessConfig(
    crop: CropConfig.banner,
    compress: CompressConfig.high,
    convertTo: ImageFormat.jpg,
  );

  static const thumbnail = ImageProcessConfig(
    compress: CompressConfig.thumbnail,
    convertTo: ImageFormat.jpg,
  );
}

/// Config for the picking step
class ImagePickerConfig {
  /// Max image width during picking (before processing)
  final double? maxWidth;

  /// Max image height during picking (before processing)
  final double? maxHeight;

  /// Quality applied at pick time 0–100
  final int imageQuality;

  /// Max number of images for multi-pick
  final int maxFiles;

  /// Use front camera for selfies
  final bool preferFrontCamera;

  /// File extensions allowed for file picker
  final List<String> allowedExtensions;

  const ImagePickerConfig({
    this.maxWidth,
    this.maxHeight,
    this.imageQuality = 100, // process later, pick at full quality
    this.maxFiles = 10,
    this.preferFrontCamera = false,
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'webp', 'heic'],
  });
}
