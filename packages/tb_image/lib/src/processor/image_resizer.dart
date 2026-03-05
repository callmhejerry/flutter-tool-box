// lib/src/processor/image_resizer.dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/image_config.dart';
import '../models/image_format.dart';

class ImageResizer {
  /// Resize a file to exact dimensions and return the resized file.
  Future<File> resize(
    File file,
    ResizeConfig config, {
    ImageFormat? outputFormat,
  }) async {
    final format = outputFormat ?? ImageFormat.fromExtension(file.path);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('tb_image: Could not decode image at ${file.path}');
    }

    final resized = config.maintainAspectRatio
        ? img.copyResize(
            image,
            width: config.width,
            height: config.height,
            maintainAspect: true,
            interpolation: img.Interpolation.linear,
          )
        : img.copyResize(
            image,
            width: config.width,
            height: config.height,
            maintainAspect: false,
            interpolation: img.Interpolation.linear,
          );

    final outPath = await _buildOutputPath(file.path, format);
    final outFile = File(outPath);

    final encoded = _encode(resized, format);
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
    return p.join(dir.path, '${name}_resized_$timestamp${format.extension}');
  }
}
