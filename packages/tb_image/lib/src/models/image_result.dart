// lib/src/models/image_result.dart

import 'dart:io';
import '../models/image_format.dart';

/// The result of a pick or process operation.
class ImageResult {
  /// The final processed (or picked) file
  final File file;

  /// File size in bytes after processing
  final int sizeInBytes;

  /// Final image width in pixels
  final int? width;

  /// Final image height in pixels
  final int? height;

  /// Output format
  final ImageFormat format;

  const ImageResult({
    required this.file,
    required this.sizeInBytes,
    required this.format,
    this.width,
    this.height,
  });

  /// File size in KB
  double get sizeInKB => sizeInBytes / 1024;

  /// File size in MB
  double get sizeInMB => sizeInBytes / (1024 * 1024);

  /// Human readable size e.g. "1.2 MB" or "340 KB"
  String get readableSize {
    if (sizeInMB >= 1) return '${sizeInMB.toStringAsFixed(1)} MB';
    return '${sizeInKB.toStringAsFixed(0)} KB';
  }

  /// File name without path
  String get fileName => file.path.split('/').last;

  @override
  String toString() =>
      'ImageResult(file: $fileName, size: $readableSize, '
      'dimensions: ${width}x$height, format: ${format.name})';
}
