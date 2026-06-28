import 'dart:convert';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}

class FcmNotificationService {
  FcmNotificationService._();
  static final instance = FcmNotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      // 1. Minta izin notifikasi
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      // 2. Setup flutter_local_notifications (untuk foreground)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _localNotif.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      // 3. Daftarkan background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Tampilkan notifikasi saat app di foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Kirim token ke backend (non-blocking, ada timeout di dalamnya)
      unawaited(_uploadToken());

      // 6. Refresh token jika berubah
      _fcm.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      // Jangan biarkan kegagalan FCM menghambat / merusak startup app
      // ignore: avoid_print
      print('FcmNotificationService.init error: $e');
    }
  }

  Future<void> _uploadToken() async {
    try {
      final token = await _fcm.getToken().timeout(const Duration(seconds: 8));
      if (token != null) await _sendTokenToBackend(token);
    } catch (_) {
      // gagal ambil token tidak boleh mengganggu app
    }
  }

  Future<void> uploadTokenAfterLogin() async {
    await _uploadToken();
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final headers = await AuthService.instance
          .jsonHeadersWithAuth()
          .timeout(const Duration(seconds: 5));
      await http
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/fcm-token'),
            headers: headers,
            body: jsonEncode({'fcm_token': token}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // diam-diam gagal, tidak kritis untuk jalannya app
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    const channel = AndroidNotificationChannel(
      'supplement_reminder',
      'Pengingat Suplemen',
      importance: Importance.high,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}