// lib/src/processor/image_compressor.dart

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/image_config.dart';
import '../models/image_format.dart';

class ImageCompressor {
  /// Compress a file and return the compressed file.
  Future<File> compress(
    File file,
    CompressConfig config, {
    ImageFormat? outputFormat,
  }) async {
    final format = outputFormat ?? ImageFormat.fromExtension(file.path);
    final outPath = await _buildOutputPath(file.path, format);

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: config.quality,
      minWidth: config.maxWidth ?? 1920,
      minHeight: config.maxHeight ?? 1920,
      format: _toCompressFormat(format),
      keepExif: false,
    );

    if (result == null) {
      throw Exception('tb_image: Compression failed for ${file.path}');
    }

    return File(result.path);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  CompressFormat _toCompressFormat(ImageFormat format) => switch (format) {
    ImageFormat.jpg => CompressFormat.jpeg,
    ImageFormat.png => CompressFormat.png,
    ImageFormat.webp => CompressFormat.webp,
  };

  Future<String> _buildOutputPath(String inputPath, ImageFormat format) async {
    final dir = await getTemporaryDirectory();
    final name = p.basenameWithoutExtension(inputPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '${name}_compressed_$timestamp${format.extension}');
  }
}
