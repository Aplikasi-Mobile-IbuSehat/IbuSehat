import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/pages/onboarding/onboarding_page.dart';
import 'package:mobile/pages/catat_tidur_page.dart';
import 'package:mobile/pages/riwayat_tidur_page.dart';
import 'package:mobile/pages/sleep/sleep_dashboard_page.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:mobile/screens/tracking_screen.dart';
import 'package:mobile/services/tracking_notifications.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

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

      home: const _AppEntry(),
      routes: {
        '/tracking': (_) => const TrackingScreen(),
        '/sleep': (_) => const SleepDashboardPage(),
        '/sleep-input': (_) => const CatatTidurPage(),
        '/riwayat-tidur': (_) => const RiwayatTidurPage(),
      },
    );
  }
}

/// Menentukan halaman awal: login → onboarding (sekali) → beranda.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final loggedIn = await AuthService.instance.isLoggedIn;
    final onboardingDone = await AuthService.instance.isOnboardingDone;
    if (!mounted) return;
    setState(() {
      if (!loggedIn) {
        _home = const AuthPage();
      } else if (!onboardingDone) {
        _home = const OnboardingPage();
      } else {
        _home = const MainPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _home!;
  }
}
