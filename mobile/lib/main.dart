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

  await Firebase.initializeApp();
  await FcmNotificationService.instance.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await initializeDateFormatting('id', null);
  await TrackingNotifications.init(appNavigatorKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) => SleepProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    appThemeController.addListener(_onThemeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openTrackingIfLaunchedFromNotification();
    });
  }

  @override
  void dispose() {
    appThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openTrackingIfLaunchedFromNotification() async {
    final details = await TrackingNotifications.getLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    if (details!.notificationResponse?.payload !=
        TrackingNotifications.payloadOpenTracking) {
      return;
    }
    if (!mounted) return;
    appNavigatorKey.currentState?.pushNamed<void>('/tracking');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appThemeController.themeMode,
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
