import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/pages/diet/diet_page.dart';
import 'package:mobile/pages/progress/progress_page.dart';
import 'package:mobile/pages/settings/settings_page.dart';
import 'package:mobile/pages/workout/workout_page.dart';
import 'package:mobile/widgets/app_navbar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Default to Diet Page

  final List<Widget> _pages = [
    const ProgressPage(),
    const DietPage(),
    const WorkoutPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: _pages[_currentIndex],
        bottomNavigationBar: AppNavbar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
