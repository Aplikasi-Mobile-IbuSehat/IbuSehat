import 'package:flutter/material.dart';
import 'package:mobile/pages/beranda/welcome_dialog.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/services/streak_service.dart';
import 'package:mobile/models/streak_models.dart';
import 'package:provider/provider.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/app_header_actions.dart';
import 'package:mobile/pages/beranda/widgets/weekly_activity_card.dart';
import 'package:mobile/pages/beranda/widgets/progress_today_section.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({
    super.key,
    this.onTabSelected,
    this.scrollController,
    this.refreshToken = 0,
  });

  final void Function(int)? onTabSelected;
  final ScrollController? scrollController;
  final int refreshToken;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  static bool _hasShownWelcomeDialog = false;
  late final ScrollController _scrollController;
  bool _isScrolled = false;
  
  // Streak data
  StreakData? _streakData;
  bool _isLoadingStreak = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    
    _fetchStreakData();
    _fetchSleepData();
    _fetchProgressData();

    if (!_hasShownWelcomeDialog) {
      _hasShownWelcomeDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const WelcomeDialog(),
        );
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('=== BERANDA: page focused, refreshing...');
      _fetchStreakData();
      _fetchSleepData();
      _fetchProgressData();
    }
  }

  @override
  void didUpdateWidget(BerandaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _refreshAll();
    }
  }

  void _refreshAll() {
    _fetchStreakData();
    _fetchSleepData();
    _fetchProgressData();
  }
  
  Future<void> _fetchProgressData() async {
    print('=== BERANDA: fetching progress data...');
    try {
      final progressProvider = context.read<ProgressProvider>();
      await progressProvider.fetchSummary();
      print('=== BERANDA: progress data fetched');
    } catch (e) {
      debugPrint('Error fetching progress data: $e');
    }
  }
  
  Future<void> _fetchSleepData() async {
    print('=== BERANDA: fetching sleep data...');
    try {
      final sleepProvider = context.read<SleepProvider>();
      await sleepProvider.fetchWeeklySummary();
      print('=== BERANDA: sleep data fetched');
    } catch (e) {
      debugPrint('Error fetching sleep data: $e');
    }
  }
  
  Future<void> _fetchStreakData() async {
    if (_isLoadingStreak) return;
    
    print('=== BERANDA: fetching streak data...');
    
    setState(() {
      _isLoadingStreak = true;
    });
    
    try {
      final data = await StreakService().getStreakData();
      if (mounted) {
        setState(() {
          _streakData = data;
          _isLoadingStreak = false;
        });
        print('=== BERANDA: streakActive=${_streakData?.streakActive}');
        print('=== BERANDA: calendar days=${_streakData?.calendar.length}');
      }
    } catch (e) {
      debugPrint('Error fetching streak data: $e');
      if (mounted) {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    }
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 5;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    WidgetsBinding.instance.removeObserver(this);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void resetScrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _goToTab(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? darkTextPrimary : lightTextPrimary;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? darkBackground : lightBackground,
            surfaceTintColor: Colors.transparent,
            elevation: _isScrolled ? 1 : 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 65.0,
            titleSpacing: 20,
            title: Text(
              'IbuSehat',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: titleColor,
                fontSize: 26,
                letterSpacing: -1.0,
              ),
            ),
            actions: [
              AppHeaderActions(titleColor: titleColor),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WeeklyActivityCard(
                    streakData: _streakData,
                    onRefreshStreak: _fetchStreakData,
                  ),
                  const SizedBox(height: 24),
                  ProgressTodaySection(
                    onTabSelected: _goToTab,
                  ),
                  const SizedBox(height: 16), // Memberikan sedikit ruang bawah
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
