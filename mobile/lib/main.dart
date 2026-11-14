import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mobile/loading_screen/loading_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/services/fcm_service.dart';
import 'package:mobile/pages/catat_tidur_page.dart';
import 'package:mobile/pages/riwayat_tidur_page.dart';
import 'package:mobile/pages/sleep/sleep_dashboard_page.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/screens/tracking_screen.dart';
import 'package:mobile/services/tracking_notifications.dart';

/// Used for notification tap → [Navigator.pushNamed] `/tracking`.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('FlutterError.onError: ${details.exception}');
    debugPrint('FlutterError stack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher.onError: $error');
    debugPrint('PlatformDispatcher stack: $stack');
    return true;
  };

  // Hanya init yang BENAR-BENAR wajib sebelum runApp.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await initializeDateFormatting('id', null);
  } catch (e) {
    debugPrint('Date formatting init error: $e');
  }

  try {
    await TrackingNotifications.init(appNavigatorKey);
  } catch (e) {
    debugPrint('TrackingNotifications init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SleepProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider.value(value: appThemeController),
      ],
      child: const MyApp(),
    ),
  );

  // FCM tidak kritis untuk render UI pertama → jalankan di background
  // setelah app tampil, supaya tidak ada kemungkinan menggantung dan
  // menyebabkan layar putih.
  unawaited(FcmNotificationService.instance.init());

  // Handle notification tap that launched the app
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final details = await TrackingNotifications.getLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    if (details!.notificationResponse?.payload != TrackingNotifications.payloadOpenTracking) return;
    appNavigatorKey.currentState?.pushNamed<void>('/tracking');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp hanya ketika AppThemeController memberitahu adanya perubahan tema.
    final themeMode = context.watch<AppThemeController>().themeMode;

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      home: const SplashScreen(),
      routes: {
        '/tracking': (_) => const TrackingScreen(),
        '/sleep': (_) => const SleepDashboardPage(),
        '/sleep-input': (_) => const CatatTidurPage(),
        '/riwayat-tidur': (_) => const RiwayatTidurPage(),
      },
    );
  }
}
