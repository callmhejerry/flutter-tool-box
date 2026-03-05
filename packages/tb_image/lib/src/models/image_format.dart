// lib/src/models/image_format.dart

/// Supported image output formats.
enum ImageFormat {
  jpg,
  png,
  webp;

  /// File extension including the dot
  String get extension => switch (this) {
    ImageFormat.jpg => '.jpg',
    ImageFormat.png => '.png',
    ImageFormat.webp => '.webp',
  };

  /// MIME type
  String get mimeType => switch (this) {
    ImageFormat.jpg => 'image/jpeg',
    ImageFormat.png => 'image/png',
    ImageFormat.webp => 'image/webp',
  };

  /// Infer format from file extension
  static ImageFormat fromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => ImageFormat.jpg,
      'png' => ImageFormat.png,
      'webp' => ImageFormat.webp,
      _ => ImageFormat.jpg, // default fallback
    };
  }
}
