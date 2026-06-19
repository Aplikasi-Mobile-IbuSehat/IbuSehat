import 'package:flutter/material.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';
import 'package:mobile/pages/beranda/streak_detail_page.dart';
import 'package:mobile/pages/beranda/welcome_dialog.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/app_header_actions.dart';

// Design tokens — mockup IbuSehat Dashboard
const _kPrimary = Color(0xFF6C4DFF);
const _kPrimaryLight = Color(0xFF8B5CF6);
const _kVeryLightPurple = Color(0xFFF3EEFF);
const _kGradientPurpleEnd = Color(0xFFEAE0FF);
const _kSuccess = Color(0xFF22C55E);
const _kBlue = Color(0xFF3B82F6);
const _kPink = Color(0xFFEC4899);
const _kOrange = Color(0xFFF59E0B);
const _kCardRadius = 24.0;

/// Tinggi tetap komponen kartu aktivitas (lebih tinggi agar rapat ke navbar).
const _kWeeklyPillHeight = 102.0;

enum _DayStatus { empty, check, progress, fire }

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, this.onTabSelected});

  final void Function(int)? onTabSelected;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  static bool _hasShownWelcomeDialog = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

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
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 5;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? darkTextPrimary : lightTextPrimary;
    final textPrimary = titleColor;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 95.0,
              backgroundColor: _isScrolled
                  ? (isDark ? darkBackground : lightBackground)
                  : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _isScrolled ? 1 : 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                AppHeaderActions(titleColor: titleColor),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                centerTitle: false,
                title: Text(
                  'IbuSehat',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWeeklyActivityCard(
                      context,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 24),
                    _buildProgressTodaySection(
                      context,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surface: surface,
                      border: border,
                      isDark: isDark,
                    ),
                    SizedBox(height: bottomInset),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivityCard(
    BuildContext context, {
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
    required Color border,
  }) {
    const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const dayStatuses = [
      _DayStatus.check,
      _DayStatus.progress,
      _DayStatus.empty,
      _DayStatus.check,
      _DayStatus.fire,
      _DayStatus.check,
      _DayStatus.empty,
    ];
    final activeCount = dayStatuses.where((status) => status != _DayStatus.empty).length;
    final currentStreak = activeCount;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [_kVeryLightPurple, _kGradientPurpleEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? surface : null,
        border: isDark ? Border.all(color: border) : null,
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aktivitas 7 Hari Terakhir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _showStreakInfoDialog(
                        context,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        surface: surface,
                      ),
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
                    color: surface,
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
                        'Konsisten selama $currentStreak hari berturut turut',
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
                                currentStreak: currentStreak,
                                longestStreak: currentStreak,
                              ),
                            ),
                          );
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
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WeekDayPill(
                      label: dayLabels[index],
                      date: '${day.day}/${day.month}',
                      status: dayStatuses[index],
                      isToday: isToday,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
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

  Widget _buildProgressTodaySection(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
    required Color border,
    required bool isDark,
  }) {
    final items = <Widget>[
      _buildProgressCard(
        title: 'Olahraga',
        value: '32 menit',
        target: 'Target 50 menit',
        percent: 64,
        progress: 0.64,
        icon: Icons.directions_run_rounded,
        iconColor: _kPrimary,
        iconBg: isDark ? _kPrimary.withValues(alpha: 0.15) : _kVeryLightPurple,
        barColor: _kPrimary,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surface: surface,
        border: border,
        isDark: isDark,
      ),
      _buildProgressCard(
        title: 'Air Putih',
        value: '6 gelas',
        target: 'Target 8 gelas',
        percent: 75,
        progress: 0.75,
        icon: Icons.water_drop_rounded,
        iconColor: _kBlue,
        iconBg: isDark ? _kBlue.withValues(alpha: 0.15) : const Color(0xFFDBEAFE),
        barColor: _kBlue,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surface: surface,
        border: border,
        isDark: isDark,
      ),
      _buildProgressCard(
        title: 'Nutrisi',
        value: '1200 kkal',
        target: 'Target 1800 kkal',
        percent: 67,
        progress: 0.67,
        icon: Icons.restaurant_rounded,
        iconColor: _kSuccess,
        iconBg: isDark ? _kSuccess.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
        barColor: _kSuccess,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surface: surface,
        border: border,
        isDark: isDark,
      ),
      _buildProgressCard(
        title: 'Skincare',
        value: '1x',
        target: 'Target 2x',
        percent: 50,
        progress: 0.5,
        icon: Icons.spa_rounded,
        iconColor: _kPink,
        iconBg: isDark ? _kPink.withValues(alpha: 0.15) : const Color(0xFFFCE7F3),
        barColor: _kPink,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surface: surface,
        border: border,
        isDark: isDark,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => _goToTab(1),
              child: Text(
                'Lihat detail >',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
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
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
    required Color border,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
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
              backgroundColor: isDark ? darkBorder : const Color(0xFFF3F4F6),
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
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
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

  void _showStreakInfoDialog(
    BuildContext context, {
    required Color textPrimary,
    required Color textSecondary,
    required Color surface,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
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
            Text(
              'Informasi Streak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Fitur ini digunakan untuk melacak konsistensi aktivitas harian kamu.\n\n'
          'Setiap kali kamu menyelesaikan workout atau mencatat kesehatan, '
          'streak akan bertambah.',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
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
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final String date;
  final _DayStatus status;
  final bool isToday;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kWeeklyPillHeight,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isToday ? _kPrimary : border,
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
                  color: isToday ? _kPrimary : textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
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
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: _kSuccess),
        );
      case _DayStatus.progress:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _kVeryLightPurple,
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
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
            border: Border.all(color: border, width: 1.5),
          ),
        );
    }
  }
}
