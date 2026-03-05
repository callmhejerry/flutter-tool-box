``` dart
final updateService = UpdateService(
  config: UpdateConfig(
    versionCheckUrl: 'https://api.myapp.com/version',
    iosAppStoreUrl: 'https://apps.apple.com/app/id123456789',
    androidPackageName: 'com.myapp.example',
    enableShorebird: true,           // ← just this
    silentPatchDownload: true,       // download without prompting
    autoRestartOnPatch: false,       // show banner instead of auto restart
  ),
);
```

---

## Complete Priority Flow
```
checkForUpdate()
    │
    ├── Shorebird enabled?
    │       │
    │       ├── patch already downloaded?  → patchReadyToRestart
    │       │       └── UpdateBanner shows "Restart" button
    │       │
    │       ├── patch available?           → patchDownloading
    │       │       └── downloads silently in background
    │       │           UpdateBanner shows spinner
    │       │           when done → emits patchReadyToRestart
    │       │
    │       └── up to date?               → fall through to store check
    │
    └── Store check
            ├── Android: Play Store priority
            │       ├── high priority → immediate (full screen)
            │       └── low priority  → flexible (background + banner)
            │
            └── iOS: backend version check
                    ├── below minimum → UpdateWall (non-dismissible)
                    └── below latest  → UpdateDialog (dismissible)

```