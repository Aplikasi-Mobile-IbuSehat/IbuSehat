import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/chatbot/chatbot_page.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';
import 'package:mobile/pages/beranda/streak_detail_page.dart';
import 'package:mobile/pages/beranda/welcome_dialog.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/widgets/app_background.dart';
import 'package:mobile/services/streak_service.dart';
import 'package:mobile/models/streak_models.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Design tokens — mockup IbuSehat Dashboard
const _kPrimary = Color(0xFF6C4DFF);
const _kPrimaryLight = Color(0xFF8B5CF6);
const _kVeryLightPurple = Color(0xFFF3EEFF);
const _kGradientPurpleEnd = Color(0xFFEAE0FF);
const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kSuccess = Color(0xFF22C55E);
const _kBlue = Color(0xFF3B82F6);
const _kPink = Color(0xFFEC4899);
const _kOrange = Color(0xFFF59E0B);
const _kCardRadius = 24.0;

/// Tinggi tetap komponen kartu aktivitas (lebih tinggi agar rapat ke navbar).
const _kWeeklyPillHeight = 102.0;

enum _DayStatus { empty, check, progress, fire }

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, this.onTabSelected, this.scrollController});

  final void Function(int)? onTabSelected;
  final ScrollController? scrollController;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  static bool _hasShownWelcomeDialog = false;
  late final ScrollController _scrollController;
  
  // Streak data
  StreakData? _streakData;
  bool _isLoadingStreak = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
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

  @override
  void dispose() {
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

  /// Ruang tepat di atas bottom nav (extendBody) — selaras tinggi AppNavbar.
  double _bottomContentInset(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // AppNavbar: padding 20 + ikon+label ~42 (rapat, hindari gap berlebih)
    const navBarContentHeight = 44.0;
    return safeBottom + navBarContentHeight;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = _bottomContentInset(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWeeklyActivityCard(context),
                      const SizedBox(height: 24),
                      _buildProgressTodaySection(context),
                      SizedBox(height: bottomInset),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 8, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'IbuSehat',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1235),
                fontSize: 22,
                letterSpacing: -1.0,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: SvgPicture.asset(
                  'assets/icons/sparkles_premium.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/message_circle.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF1F1235),
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatbotPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityCard(BuildContext context) {
    const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    
    final currentStreak = _streakData?.streakActive ?? 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    // Get last 7 days from calendar
    final last7Days = _streakData?.calendar
        .where((day) {
          final date = DateTime.parse(day.date);
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 date.isBefore(now.add(const Duration(days: 1)));
        })
        .toList() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kVeryLightPurple, _kGradientPurpleEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas 7 Hari Terakhir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _showStreakInfoDialog(context),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShareAchievementPage(
                              streakDays: currentStreak,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: _kPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Bagikan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 148),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kPrimaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 52,
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 52,
                    color: Color(0xFFFBBF24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Streak Saat Ini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currentStreak Hari 🔥',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Konsisten selama ${_streakData?.streakActive ?? 0} hari berturut-turut',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 70,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StreakDetailPage(
                                currentStreak: _streakData?.streakActive ?? 0,
                                longestStreak: _streakData?.streakLongest ?? 0,
                              ),
                            ),
                          ).then((_) {
                            // Refresh streak data when returning from detail page
                            _fetchStreakData();
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _kWeeklyPillHeight,
            child: Row(
              children: List.generate(7, (index) {
                final day = startOfWeek.add(Duration(days: index));
                final isToday = day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;
                
                // Find matching calendar day
                CalendarDay? calendarDay;
                if (last7Days.isNotEmpty) {
                  try {
                    calendarDay = last7Days.firstWhere(
                      (cd) {
                        final cdDate = DateTime.parse(cd.date);
                        return cdDate.year == day.year &&
                               cdDate.month == day.month &&
                               cdDate.day == day.day;
                      },
                    );
                  } catch (e) {
                    // No matching day found
                  }
                }
                
                // Determine status from calendar day
                _DayStatus status = _DayStatus.empty;
                if (calendarDay != null) {
                  // Show green checkmark for all completed days (including today)
                  if (calendarDay.status == 'completed') {
                    status = _DayStatus.check;
                  } else if (calendarDay.status == 'today' && isToday) {
                    // Only show progress if today and NOT completed yet
                    status = _DayStatus.progress;
                  }
                }
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WeekDayPill(
                      label: dayLabels[index],
                      date: '${day.day}/${day.month}',
                      status: status,
                      isToday: isToday,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTodaySection(BuildContext context) {
    // Get sleep data from provider
    final sleepProvider = context.watch<SleepProvider>();
    final sleepTotalHours = sleepProvider.weeklyTotalHours;
    final sleepPercent = sleepProvider.weeklyProgressPercent;
    final sleepProgress = sleepPercent / 100.0;

    // Get progress data from provider
    final progressProvider = context.watch<ProgressProvider>();
    final progressData = progressProvider.summary;

    // Olahraga dari API
    final int olahragaMenit = progressData?.weekly.workout.today ?? 0;
    final int olahragaPercent = progressData?.weekly.workout.percent ?? 0;
    final double olahragaProgress = olahragaPercent / 100.0;
    final int olahragaTargetMinutes = progressData?.weekly.workout.targetMinutes ?? 75;
    final String olahragaTargetText = 'Target mingguan $olahragaTargetMinutes menit';

    // Air putih dari API
    final int airPutihMl = progressData?.weekly.water.today ?? 0;
    final int airPutihPercent = progressData?.weekly.water.percent ?? 0;
    final double airPutihProgress = airPutihPercent / 100.0;
    final int airPutihTargetMl = progressData?.weekly.water.targetMl ?? 14000;
    final String airPutihTargetText = 'Target mingguan ${NumberFormat('#,###', 'id').format(airPutihTargetMl ~/ 1000)} liter';

    // Nutrisi dari API
    final int nutrisiKkal = progressData?.weekly.nutrition.today ?? 0;
    final int nutrisiPercent = progressData?.weekly.nutrition.percent ?? 0;
    final double nutrisiProgress = nutrisiPercent / 100.0;
    final int nutrisiTargetKkal = progressData?.weekly.nutrition.targetKkal ?? 14469;
    final String nutrisiTargetText = 'Target Mingguan ${NumberFormat('#,###', 'id').format(nutrisiTargetKkal)} kkal';
    
    final items = <Widget>[
      _buildProgressCard(
        title: 'Olahraga',
        value: '$olahragaMenit menit',
        target: olahragaTargetText,
        percent: olahragaPercent,
        progress: olahragaProgress,
        icon: Icons.directions_run_rounded,
        iconColor: _kPrimary,
        iconBg: _kVeryLightPurple,
        barColor: _kPrimary,
      ),
      _buildProgressCard(
        title: 'Air Putih',
        value: '$airPutihMl ML',
        target: airPutihTargetText,
        percent: airPutihPercent,
        progress: airPutihProgress,
        icon: Icons.water_drop_rounded,
        iconColor: _kBlue,
        iconBg: const Color(0xFFDBEAFE),
        barColor: _kBlue,
      ),
      _buildProgressCard(
        title: 'Nutrisi',
        value: '$nutrisiKkal kkal',
        target: nutrisiTargetText,
        percent: nutrisiPercent,
        progress: nutrisiProgress,
        icon: Icons.restaurant_rounded,
        iconColor: _kSuccess,
        iconBg: const Color(0xFFDCFCE7),
        barColor: _kSuccess,
      ),
      _buildProgressCard(
        title: 'Jam Tidur',
        value: '${sleepTotalHours.toStringAsFixed(1)} jam',
        target: 'Target Mingguan 49 jam',
        percent: sleepPercent,
        progress: sleepProgress,
        icon: Icons.bedtime,
        iconColor: _kPink,
        iconBg: const Color(0xFFFCE7F3),
        barColor: _kPink,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress Minggu Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => _goToTab(1),
              child: const Text(
                'Lihat detail >',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 12,
          childAspectRatio: 1.65,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items,
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required String target,
    required int percent,
    required double progress,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color barColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kTextSecondary,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  target,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: _kTextSecondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStreakInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            const Text(
              'Informasi Streak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Fitur ini digunakan untuk melacak konsistensi aktivitas harian kamu.\n\n'
          'Setiap kali kamu menyelesaikan workout atau mencatat kesehatan, '
          'streak akan bertambah.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mengerti',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.label,
    required this.date,
    required this.status,
    required this.isToday,
  });

  final String label;
  final String date;
  final _DayStatus status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kWeeklyPillHeight,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isToday ? _kPrimary : const Color(0xFFE5E7EB),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isToday ? _kPrimary : _kTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),
          _statusIcon(),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (status) {
      case _DayStatus.check:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _kSuccess,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        );
      case _DayStatus.progress:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary, width: 2),
          ),
          child: const Icon(
            Icons.directions_run_rounded,
            size: 12,
            color: _kPrimary,
          ),
        );
      case _DayStatus.fire:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEDD5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: _kOrange,
          ),
        );
      case _DayStatus.empty:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
          ),
        );
    }
  }
}
