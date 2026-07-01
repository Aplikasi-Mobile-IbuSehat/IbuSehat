import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

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
      // Setup flutter_local_notifications (untuk foreground)
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

  /// Memeriksa status izin notifikasi. Jika belum diizinkan, tampilkan dialog modern.
  /// Return true jika izin sudah ada atau berhasil diberikan, false jika ditolak ("Nanti").
  Future<bool> checkAndPromptPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Tampilkan dialog modern
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aktifkan Notifikasi?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pengingat memerlukan notifikasi agar dapat mengingatkan Anda. Aktifkan sekarang?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Nanti',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Aktifkan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * anim1.value),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    if (result == true) {
      // Panggil FCM request permission terlebih dahulu
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      
      final reqStatus = await Permission.notification.request();
      if (reqStatus.isGranted) {
        // Karena kita menunda pengambilan izin dari awal app,
        // ambil FCM token sekarang supaya server bisa mengirim push notif.
        await uploadTokenAfterLogin();
        return true;
      } else {
        // Jika dialog sistem tidak muncul karena diblokir/permanently denied,
        // buka pengaturan aplikasi agar user bisa mengaktifkannya secara manual.
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        return false;
      }
    }

    return false;
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