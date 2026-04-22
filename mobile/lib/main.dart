import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/screens/tracking_screen.dart';
import 'package:mobile/services/tracking_notifications.dart';

import 'package:intl/date_symbol_data_local.dart';

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

  await initializeDateFormatting('id', null);
  await TrackingNotifications.init(appNavigatorKey);
  runApp(const MyApp());
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openTrackingIfLaunchedFromNotification();
    });
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
      home: const AuthPage(),
      routes: {
        '/tracking': (_) => const TrackingScreen(),
      },
    );
  }
}
