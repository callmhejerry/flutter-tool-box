// lib/src/storage_keys.dart

/// Extend or use this as a pattern in your app to centralise
/// all storage key strings.
///
/// ```dart
/// // In your app:
/// abstract final class StorageKeys {
///   // Secure
///   static const accessToken  = 'access_token';
///   static const refreshToken = 'refresh_token';
///
///   // KeyValue
///   static const hasSeenOnboarding = 'has_seen_onboarding';
///   static const appTheme          = 'app_theme';
///   static const appLocale         = 'app_locale';
///
///   // Cache — use prefixes for group invalidation
///   static const userPrefix        = 'user:';
///   static String userById(String id) => 'user:$id';
///   static String feedPage(int page) => 'feed:page:$page';
/// }
/// ```
abstract final class StorageKeys {
  StorageKeys._();
}
