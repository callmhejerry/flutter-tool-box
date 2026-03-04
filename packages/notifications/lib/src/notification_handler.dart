import 'package:flutter/material.dart';

/// The app implements this and passes it to NotificationService.
/// It receives the data payload and is responsible for navigation.
abstract class NotificationHandler {
  void onNotificationTap(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  );
}
