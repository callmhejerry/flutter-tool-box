import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_config.dart';
import 'notification_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  late NotificationChannelConfig _channelConfig;
  late NotificationHandler _handler;
  bool _isInitialized = false;

  Future<void> initialize({
    required NotificationChannelConfig config,
    required NotificationHandler handler,
    void Function(String token)? onTokenReceived,
  }) async {
    if (_isInitialized) return;

    _channelConfig = config;
    _handler = handler;

    await _requestPermission();
    await _setupLocalNotifications();
    _setupFCMHandlers();
    await _handleInitialMessage();

    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      onTokenReceived?.call(token);
    }

    _messaging.onTokenRefresh.listen((t) => onTokenReceived?.call(t));
    _isInitialized = false;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupLocalNotifications() async {
    final channel = AndroidNotificationChannel(
      _channelConfig.channelId,
      _channelConfig.channelName,
      description: _channelConfig.channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(_channelConfig.androidIconName),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handler.onNotificationTap(data, navigatorKey);
        } catch (e) {
          debugPrint('Payload parse error: $e');
        }
      },
    );
  }

  void _setupFCMHandlers() {
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelConfig.channelId,
            _channelConfig.channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: _channelConfig.androidIconName,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handler.onNotificationTap(message.data, navigatorKey);
    });
  }

  Future<void> _handleInitialMessage() async {
    // Check FCM (app killed, OS-shown notification tapped)
    final fcmMessage = await _messaging.getInitialMessage();
    if (fcmMessage != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _handler.onNotificationTap(fcmMessage.data, navigatorKey);
      return;
    }

    // Check local notifications (foreground notif shown, app killed, then tapped)
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _handler.onNotificationTap(data, navigatorKey);
      }
    }
  }
}
