import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/pages/beranda/beranda_page.dart';
import 'package:mobile/pages/diet/diet_page.dart';
import 'package:mobile/pages/progress/progress_page.dart';
import 'package:mobile/pages/profile/profile_page.dart';
import 'package:mobile/pages/workout/workout_page.dart';
import 'package:mobile/widgets/app_navbar.dart';
import 'package:mobile/pages/beranda/sleep_fab.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.initialIndex = 0});

  /// Bottom tab: 0 Beranda, 1 Progress, 2 Diet, 3 Workout, 4 Profile
  final int initialIndex;
  const MainPage({
    super.key,
    this.initialIndex = 0,
    this.progressRefreshToken = 0,
  });

  /// Bottom tab: 0 Beranda, 1 Progress, 2 Diet, 3 Workout, 4 Profile
  final int initialIndex;
  final int progressRefreshToken;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  late final List<Widget> _pages = [
    BerandaPage(
      onTabSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
    ProgressPage(refreshToken: widget.progressRefreshToken),
    const DietPage(),
    const WorkoutPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

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
        floatingActionButton: _currentIndex == 0 ? const SleepFab() : null,
      ),
    );
  }
}
