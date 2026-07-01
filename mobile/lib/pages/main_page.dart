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
  bool _showExitToast = false;

  @override
  void initState() {
    super.initState();

    AuthService.instance.syncUserFromApi();

    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  @override
  void dispose() {
    _berandaScrollController.dispose();
    super.dispose();
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
          if (!_showExitToast) {
            setState(() {
              _showExitToast = true;
            });
          }
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
            if (_showExitToast)
              Positioned(
                bottom: 97,
                left: 20,
                right: 20,
                child: _ExitToastWidget(
                  isDark: isDark,
                  onDismissed: () {
                    if (mounted) {
                      setState(() {
                        _showExitToast = false;
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

class _ExitToastWidget extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDismissed;
  const _ExitToastWidget({Key? key, required this.isDark, required this.onDismissed}) : super(key: key);

  @override
  State<_ExitToastWidget> createState() => _ExitToastWidgetState();
}

class _ExitToastWidgetState extends State<_ExitToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    
    _controller.forward();

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.5), // Mulai dari 1.5x tinggi widget di bawah (dalam navbar)
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            // Transparansi ringan (sangat ringan di-render tanpa blur)
            color: (widget.isDark ? darkSurface : lightSurface).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              width: 1,
            ),
            
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // Pindah ke kiri
            children: [
              Text(
                'Ketuk sekali lagi untuk keluar',
                style: TextStyle(
                  color: widget.isDark ? darkTextPrimary : lightTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
