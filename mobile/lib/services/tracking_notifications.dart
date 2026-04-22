import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android foreground-style tracking notification (tap opens tracking route).
class TrackingNotifications {
  TrackingNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;

  static const int notificationId = 9001;
  static const String channelId = 'ibu_sehat_tracking';
  static const String channelName = 'Pelacakan aktivitas';
  static const String payloadOpenTracking = 'open_tracking';

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Notifikasi saat melacak aktivitas',
        importance: Importance.low,
      ),
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != payloadOpenTracking) return;
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    nav.pushNamed<void>('/tracking');
  }

  static Future<void> showOrUpdate({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Menampilkan statistik pelacakan',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.navigation,
      visibility: NotificationVisibility.public,
    );
    const details = NotificationDetails(android: android);

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payloadOpenTracking,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(notificationId);
  }

  /// If the app was opened by tapping the tracking notification (cold start).
  static Future<NotificationAppLaunchDetails?> getLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }
}
