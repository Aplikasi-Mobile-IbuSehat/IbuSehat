import 'package:flutter/material.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/pages/onboarding/onboarding_page.dart';
import 'package:mobile/services/auth_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _AppEntry(),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _home!;
  }
}
