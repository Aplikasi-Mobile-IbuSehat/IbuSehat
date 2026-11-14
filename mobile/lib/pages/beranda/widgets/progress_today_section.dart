import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';

const _kPrimary = Color(0xFF6C4DFF);
const _kSuccess = Color(0xFF22C55E);
const _kBlue = Color(0xFF3B82F6);
const _kPink = Color(0xFFEC4899);
const _kVeryLightPurple = Color(0xFFF3EEFF);

final _numberFormatId = NumberFormat('#,###', 'id');

class ProgressTodaySection extends StatelessWidget {
  const ProgressTodaySection({
    super.key,
    required this.onTabSelected,
  });

  final void Function(int) onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Minggu Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => onTabSelected(1),
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
        GridView(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            WorkoutProgressCard(),
            WaterProgressCard(),
            NutritionProgressCard(),
            SleepProgressCard(),
          ],
        ),
      ],
    );
  }
}

class WorkoutProgressCard extends StatelessWidget {
  const WorkoutProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        final workout = provider.summary?.weekly.workout;
        final menit = workout?.today ?? 0;
        final percent = workout?.percent ?? 0;
        final progress = percent / 100.0;
        final targetMinutes = workout?.targetMinutes ?? 75;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ProgressCard(
          title: 'Olahraga',
          value: '$menit menit',
          target: 'Target mingguan $targetMinutes menit',
          percent: percent,
          progress: progress,
          icon: Icons.directions_run_rounded,
          iconColor: _kPrimary,
          iconBg: isDark ? _kPrimary.withValues(alpha: 0.15) : _kVeryLightPurple,
          barColor: _kPrimary,
        );
      },
    );
  }
}

class WaterProgressCard extends StatelessWidget {
  const WaterProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        final water = provider.summary?.weekly.water;
        final ml = water?.today ?? 0;
        final percent = water?.percent ?? 0;
        final progress = percent / 100.0;
        final targetMl = water?.targetMl ?? 14000;
        final targetLiterText = _numberFormatId.format(targetMl ~/ 1000);
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ProgressCard(
          title: 'Air Putih',
          value: '$ml ML',
          target: 'Target mingguan $targetLiterText liter',
          percent: percent,
          progress: progress,
          icon: Icons.water_drop_rounded,
          iconColor: _kBlue,
          iconBg: isDark ? _kBlue.withValues(alpha: 0.15) : const Color(0xFFDBEAFE),
          barColor: _kBlue,
        );
      },
    );
  }
}

class NutritionProgressCard extends StatelessWidget {
  const NutritionProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, provider, _) {
        final nutrition = provider.summary?.weekly.nutrition;
        final kkal = nutrition?.today ?? 0;
        final percent = nutrition?.percent ?? 0;
        final progress = percent / 100.0;
        final targetKkal = nutrition?.targetKkal ?? 14469;
        final targetKkalText = _numberFormatId.format(targetKkal);
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ProgressCard(
          title: 'Nutrisi',
          value: '$kkal kkal',
          target: 'Target Mingguan $targetKkalText kkal',
          percent: percent,
          progress: progress,
          icon: Icons.restaurant_rounded,
          iconColor: _kSuccess,
          iconBg: isDark ? _kSuccess.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
          barColor: _kSuccess,
        );
      },
    );
  }
}

class SleepProgressCard extends StatelessWidget {
  const SleepProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (context, provider, _) {
        final totalHours = provider.weeklyTotalHours;
        final percent = provider.weeklyProgressPercent;
        final progress = percent / 100.0;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ProgressCard(
          title: 'Jam Tidur',
          value: '${totalHours.toStringAsFixed(1)} jam',
          target: 'Target Mingguan 49 jam',
          percent: percent,
          progress: progress,
          icon: Icons.bedtime,
          iconColor: _kPink,
          iconBg: isDark ? _kPink.withValues(alpha: 0.15) : const Color(0xFFFCE7F3),
          barColor: _kPink,
        );
      },
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.target,
    required this.percent,
    required this.progress,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.barColor,
  });

  final String title;
  final String value;
  final String target;
  final int percent;
  final double progress;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

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
}
