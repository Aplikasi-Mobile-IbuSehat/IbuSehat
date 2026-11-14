import 'package:flutter/material.dart';
import 'package:mobile/models/streak_models.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';
import 'package:mobile/pages/beranda/streak_detail_page.dart';
import 'package:mobile/theme/app_colors.dart';

const _kPrimary = Color(0xFF6C4DFF);
const _kVeryLightPurple = Color(0xFFF3EEFF);
const _kGradientPurpleEnd = Color(0xFFEAE0FF);
const _kOrange = Color(0xFFF59E0B);
const _kSuccess = Color(0xFF22C55E);
const _kCardRadius = 24.0;
const _kWeeklyPillHeight = 102.0;

enum DayStatus { empty, check, progress, fire }

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({
    super.key,
    required this.streakData,
    required this.onRefreshStreak,
  });

  final StreakData? streakData;
  final VoidCallback onRefreshStreak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    final currentStreak = streakData?.streakActive ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF2E1A47), Color(0xFF150B24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [_kVeryLightPurple, _kGradientPurpleEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: isDark ? Border.all(color: border.withValues(alpha: 0.3)) : null,
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
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : lightSurface,
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
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : lightSurface,
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
          StreakCard(
            streakData: streakData,
            onRefreshStreak: onRefreshStreak,
          ),
          const SizedBox(height: 10),
          WeekCalendar(
            streakData: streakData,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            lightSurface: lightSurface,
            lightBorder: lightBorder,
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

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.streakData,
    required this.onRefreshStreak,
  });

  final StreakData? streakData;
  final VoidCallback onRefreshStreak;

  @override
  Widget build(BuildContext context) {
    final currentStreak = streakData?.streakActive ?? 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
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
                  'Konsisten selama ${streakData?.streakActive ?? 0} hari berturut-turut',
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
                          currentStreak: streakData?.streakActive ?? 0,
                          longestStreak: streakData?.streakLongest ?? 0,
                        ),
                      ),
                    ).then((_) {
                      onRefreshStreak();
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
                        const SizedBox(width: 2),
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
    );
  }
}

class WeekCalendar extends StatelessWidget {
  const WeekCalendar({
    super.key,
    required this.streakData,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.lightSurface,
    required this.lightBorder,
  });

  final StreakData? streakData;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color lightSurface;
  final Color lightBorder;

  static const _dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    // Get last 7 days from calendar
    final last7Days = streakData?.calendar
        .where((day) {
          final date = DateTime.parse(day.date);
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 date.isBefore(now.add(const Duration(days: 1)));
        })
        .toList() ?? [];

    return SizedBox(
      height: _kWeeklyPillHeight,
      child: Row(
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isToday = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;
          
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
            } catch (_) {}
          }
          
          DayStatus status = DayStatus.empty;
          if (calendarDay != null) {
            if (calendarDay.status == 'completed') {
              status = DayStatus.check;
            } else if (calendarDay.status == 'today' && isToday) {
              status = DayStatus.progress;
            }
          }
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: WeekDayPill(
                label: _dayLabels[index],
                date: '${day.day}/${day.month}',
                status: status,
                isToday: isToday,
                surface: isDark ? Colors.white.withValues(alpha: 0.05) : lightSurface,
                border: isDark ? Colors.white.withValues(alpha: 0.1) : lightBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class WeekDayPill extends StatelessWidget {
  const WeekDayPill({
    super.key,
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
  final DayStatus status;
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
      case DayStatus.check:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _kSuccess,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        );
      case DayStatus.progress:
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
      case DayStatus.fire:
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
      case DayStatus.empty:
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
