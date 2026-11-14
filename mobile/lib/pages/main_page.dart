import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/theme/app_colors.dart';

import 'package:mobile/pages/beranda/beranda_page.dart';
import 'package:mobile/pages/diet/diet_page.dart';
import 'package:mobile/pages/progress/progress_page.dart';
import 'package:mobile/pages/settings/settings.dart';
import 'package:mobile/pages/workout/workout_page.dart';
import 'package:mobile/widgets/app_navbar.dart';
import 'package:mobile/pages/beranda/sleep_fab.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/custom_toast.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.initialIndex = 0,
    this.progressRefreshToken = 0,
  });

  /// Bottom tab:
  /// 0 = Beranda
  /// 1 = Progress
  /// 2 = Diet
  /// 3 = Workout
  /// 4 = Profile
  final int initialIndex;

  final int progressRefreshToken;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;
  int _berandaRefreshToken = 0;
  final ScrollController _berandaScrollController = ScrollController();
  DateTime? _lastPressedAt;
  ToastData? _activeToast;

  @override
  void initState() {
    super.initState();

    AuthService.instance.syncUserFromApi();

    _currentIndex = widget.initialIndex.clamp(0, 4);

    // Daftarkan listener untuk mendengarkan toast global
    CustomToast.toastNotifier.addListener(_onToastChanged);
  }

  @override
  void dispose() {
    CustomToast.toastNotifier.removeListener(_onToastChanged);
    _berandaScrollController.dispose();
    super.dispose();
  }

  void _onToastChanged() {
    if (mounted) {
      setState(() {
        _activeToast = CustomToast.toastNotifier.value;
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      if (index == 0 && _currentIndex != 0) {
        _berandaRefreshToken++;
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          CustomToast.show(context, 'Ketuk sekali lagi untuk keluar');
          return false;
        }
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              BerandaPage(
                refreshToken: _berandaRefreshToken,
                scrollController: _berandaScrollController,
                onTabSelected: _onTabSelected,
              ),
              ProgressPage(refreshToken: widget.progressRefreshToken),
              const DietPage(),
              const WorkoutPage(),
              const SettingsPage(),
            ],
          ),
          bottomNavigationBar: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              if (_activeToast != null)
                Positioned(
                  bottom: 97,
                  left: 20,
                  right: 20,
                  child: CustomToastWidget(
                    key: ValueKey(_activeToast!.timestamp),
                    message: _activeToast!.message,
                    isError: _activeToast!.isError,
                    onDismissed: () {
                      if (mounted) {
                        setState(() {
                          _activeToast = null;
                        });
                      }
                    },
                  ),
                ),
              AppNavbar(
                currentIndex: _currentIndex,
                onTap: _onTabSelected,
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0 ? const SleepFab() : null,
        ),
      ),
    );
  }
}
