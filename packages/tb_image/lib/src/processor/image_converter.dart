// lib/src/processor/image_converter.dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/image_format.dart';

class ImageConverter {
  /// Convert a file to a different format.
  Future<File> convert(File file, ImageFormat targetFormat) async {
    // No-op if already in target format
    final currentFormat = ImageFormat.fromExtension(file.path);
    if (currentFormat == targetFormat) return file;

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('tb_image: Could not decode image at ${file.path}');
    }

    final encoded = _encode(image, targetFormat);
    final outPath = await _buildOutputPath(file.path, targetFormat);
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded);

    return outFile;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  List<int> _encode(img.Image image, ImageFormat format) => switch (format) {
    ImageFormat.jpg => img.encodeJpg(image, quality: 90),
    ImageFormat.png => img.encodePng(image),
    ImageFormat.webp => img.encodeJpg(image, quality: 90),
  };

  Future<String> _buildOutputPath(String inputPath, ImageFormat format) async {
    final dir = await getTemporaryDirectory();
    final name = p.basenameWithoutExtension(inputPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '${name}_converted_$timestamp${format.extension}');
  }
}
