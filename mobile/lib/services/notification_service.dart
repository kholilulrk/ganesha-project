import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  int _unreadCount = 0;
  void Function(int)? onUnreadChanged;

  int get unreadCount => _unreadCount;

  Future<void> initialize() async {
    await _requestPermission();

    final token = await _messaging.getToken();
    if (token != null) {
      await NotificationApiService.registerFCMToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      NotificationApiService.registerFCMToken(newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    await refreshUnreadCount();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      refreshUnreadCount();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigation handled via onUnreadChanged callback
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await NotificationApiService.getUnreadCount();
      onUnreadChanged?.call(_unreadCount);
    } catch (_) {}
  }

  Future<void> dispose() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await NotificationApiService.unregisterFCMToken(token);
    }
  }
}
