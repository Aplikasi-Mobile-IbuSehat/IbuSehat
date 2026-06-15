import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/loading_screen/loading_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmNotificationService.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
    appThemeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    appThemeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appThemeController.themeMode,
      home: const SplashScreen(),
    );
  }
}
