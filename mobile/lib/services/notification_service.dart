import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_api_service.dart';

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  int _unreadCount = 0;
  void Function(int)? onUnreadChanged;

  int get unreadCount => _unreadCount;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotif.initialize(initSettings, onDidReceiveNotificationResponse: (_) => refreshUnreadCount());

    const androidChannel = AndroidNotificationChannel(
      'ganesha_channel',
      'Notifikasi Ganesha',
      description: 'Notifikasi aplikasi Ganesha Energi',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);

    await _requestPermission();

    final token = await _messaging.getToken();
    if (token != null) {
      await NotificationApiService.registerFCMToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      NotificationApiService.registerFCMToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((msg) => _handleForegroundMessage(msg));
    FirebaseMessaging.onMessageOpenedApp.listen((_) => refreshUnreadCount());

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await refreshUnreadCount();
    }

    await refreshUnreadCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshUnreadCount();
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final payload = message.data['type'] ?? '';

    try {
      await _localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ganesha_channel',
            'Notifikasi Ganesha',
            channelDescription: 'Notifikasi aplikasi Ganesha Energi',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (_) {}

    await refreshUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await NotificationApiService.getUnreadCount();
      onUnreadChanged?.call(_unreadCount);
    } catch (_) {}
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    final token = await _messaging.getToken();
    if (token != null) {
      await NotificationApiService.unregisterFCMToken(token);
    }
  }
}
