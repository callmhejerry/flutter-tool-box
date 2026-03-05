
**Android setup**
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- For Android < 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

**iOS setup**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to pick images.</string>
```


**How to use**
```dart
final imageService = ImageService();

// ── Avatar upload ──────────────────────────────────────────────
final result = await imageService.pickAndProcess(
  source: ImageSource.gallery,
  processConfig: ImageProcessConfig.avatarUpload,
  // crop (square) → compress (medium) → convert (jpg)
);

result.when(
  success: (image) {
    print('Ready: ${image.readableSize}');  // "320 KB"
    uploadService.uploadFile(path: '/avatar', file: image.file);
  },
  failure: (f) => showSnackbar(f.message),
);

// ── Multiple images ───────────────────────────────────────────
final multiResult = await imageService.pickMultipleAndProcess(
  pickerConfig: ImagePickerConfig(maxFiles: 5),
  processConfig: ImageProcessConfig.thumbnail,
);

// ── Camera with custom crop ───────────────────────────────────
final cameraResult = await imageService.pickAndProcess(
  source: ImageSource.camera,
  processConfig: ImageProcessConfig(
    crop: CropConfig(
      ratio: CropRatio.custom,
      customRatioX: 3,
      customRatioY: 2,
      lockAspectRatio: true,
    ),
    compress: CompressConfig(quality: 80, maxWidth: 1200),
    convertTo: ImageFormat.webp,
  ),
);

// ── Process existing file ─────────────────────────────────────
final processResult = await imageService.processFile(
  existingFile,
  ImageProcessConfig(
    resize: ResizeConfig(width: 400, height: 400),
    convertTo: ImageFormat.png,
  ),
);
```