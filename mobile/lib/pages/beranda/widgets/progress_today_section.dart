import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/pages/beranda/widgets/dashboard_style.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:mobile/providers/sleep_provider.dart';
import 'package:provider/provider.dart';

/// Tinggi kartu terkecil sebelum halaman beralih ke mode gulir.
const double _minCardHeight = 104;
const double _rowGap = 10;
const double _columnGap = 10;

/// Tombol tidur melayang (SleepFab, 56 px + margin 16) menutupi pojok
/// kanan-bawah kartu Jam Tidur saat kartu memanjang sampai di atas navbar.
const double _fabCornerInset = 50;

/// Mulai tinggi kartu ini, kartu Jam Tidur menyisakan ruang di kanan bawah
/// untuk tombol tidur. Di bawahnya halaman sudah dalam mode gulir.
const double _fabAwareMinCardHeight = 110;

final _thousands = NumberFormat.decimalPattern('id');
final _oneDecimal = NumberFormat('#,##0.#', 'id');

/// Ringkasan empat metrik minggu berjalan, dalam grid 2x2 yang mengisi
/// tinggi yang diberikan (lihat BerandaPage).
class ProgressTodaySection extends StatelessWidget {
  const ProgressTodaySection({
    super.key,
    required this.onTabSelected,
  });

  final void Function(int) onTabSelected;

  /// Tinggi terkecil section ini (judul + grid dengan kartu minimum).
  static const double minHeight = 32 + 6 + _minCardHeight * 2 + _rowGap;

  @override
  Widget build(BuildContext context) {
    final s = DashboardStyle.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(child: Text('MINGGU INI', style: s.eyebrow)),
              TextButton(
                onPressed: () => onTabSelected(1),
                style: TextButton.styleFrom(
                  foregroundColor: s.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat progress',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = (constraints.maxHeight - _rowGap) / 2;

              return Column(
                children: [
                  const Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: WorkoutProgressCard()),
                        SizedBox(width: _columnGap),
                        Expanded(child: WaterProgressCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: _rowGap),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: NutritionProgressCard()),
                        const SizedBox(width: _columnGap),
                        Expanded(
                          child: SleepProgressCard(
                            avoidFabCorner:
                                cardHeight >= _fabAwareMinCardHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
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
        final target = workout?.targetMinutes ?? 75;

        return ProgressCard(
          title: 'Olahraga',
          icon: Icons.directions_run_rounded,
          color: DashboardStyle.workout,
          value: _thousands.format(workout?.totalMinutes ?? 0),
          unit: 'menit',
          target: 'dari ${_thousands.format(target)} menit',
          percent: workout?.percent ?? 0,
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
        final totalMl = water?.totalMl ?? 0;
        final targetMl = water?.targetMl ?? 14000;

        return ProgressCard(
          title: 'Air putih',
          icon: Icons.water_drop_rounded,
          color: DashboardStyle.water,
          value: _oneDecimal.format(totalMl / 1000),
          unit: 'liter',
          target: 'dari ${_oneDecimal.format(targetMl / 1000)} liter',
          percent: water?.percent ?? 0,
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
        final target = nutrition?.targetKkal ?? 14469;

        return ProgressCard(
          title: 'Nutrisi',
          icon: Icons.restaurant_rounded,
          color: DashboardStyle.nutrition,
          value: _thousands.format(nutrition?.totalKkal ?? 0),
          unit: 'kkal',
          target: 'dari ${_thousands.format(target)} kkal',
          percent: nutrition?.percent ?? 0,
        );
      },
    );
  }
}

class SleepProgressCard extends StatelessWidget {
  const SleepProgressCard({super.key, this.avoidFabCorner = false});

  /// True bila pojok kanan-bawah kartu ini tertutup tombol tidur melayang.
  final bool avoidFabCorner;

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (context, provider, _) {
        return ProgressCard(
          title: 'Tidur',
          icon: Icons.bedtime_rounded,
          color: DashboardStyle.sleep,
          value: _oneDecimal.format(provider.weeklyTotalHours),
          unit: 'jam',
          target: 'dari 49 jam',
          percent: provider.weeklyProgressPercent,
          avoidBottomRightCorner: avoidFabCorner,
        );
      },
    );
  }
}

/// Kartu satu metrik: label & persentase di atas, angka besar, lalu target
/// dan bilah progres di bawah. Kartu meregang mengikuti tinggi grid.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.target,
    required this.percent,
    this.avoidBottomRightCorner = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String target;
  final int percent;

  /// Bila true, target & bilah progres menyisakan ruang di kanan bawah
  /// kartu, yang tertutup tombol melayang.
  final bool avoidBottomRightCorner;

  @override
  Widget build(BuildContext context) {
    final s = DashboardStyle.of(context);
    final progress = (percent / 100).clamp(0.0, 1.0);

    return Semantics(
      label: '$title: $value $unit $target, $percent persen',
      excludeSemantics: true,
      child: Container(
        decoration: s.cardDecoration(),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: s.ink,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: percent > 0 ? color : s.faint,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: s.figure(28)),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: s.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(
                right: avoidBottomRightCorner ? _fabCornerInset : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: s.track,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    target,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: s.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
