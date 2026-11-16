import 'package:flutter/material.dart';
import 'package:mobile/models/streak_models.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';
import 'package:mobile/pages/beranda/streak_detail_page.dart';
import 'package:mobile/pages/beranda/widgets/dashboard_style.dart';

/// Status satu hari di minggu berjalan.
enum DayStatus { done, today, missed, future }

/// Kartu streak di dashboard.
///
/// Ciri khasnya "rantai streak": hari-hari yang selesai berturut-turut
/// tersambung menjadi satu kapsul, sehingga panjang streak terbaca dari
/// bentuknya. Seluruh kartu bisa diketuk untuk membuka detail streak.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({
    super.key,
    required this.streakData,
    required this.onRefreshStreak,
  });

  final StreakData? streakData;
  final VoidCallback onRefreshStreak;

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StreakDetailPage(
          currentStreak: streakData?.streakActive ?? 0,
          longestStreak: streakData?.streakLongest ?? 0,
        ),
      ),
    ).then((_) => onRefreshStreak());
  }

  @override
  Widget build(BuildContext context) {
    final s = DashboardStyle.of(context);
    final current = streakData?.streakActive ?? 0;
    final longest = streakData?.streakLongest ?? 0;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: s.cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(DashboardStyle.radius),
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('STREAK', style: s.eyebrow)),
                    _IconAction(
                      icon: Icons.info_outline_rounded,
                      tooltip: 'Tentang streak',
                      color: s.muted,
                      onTap: () => _showStreakInfoDialog(context, s),
                    ),
                    _IconAction(
                      icon: Icons.ios_share_rounded,
                      tooltip: 'Bagikan streak',
                      color: s.muted,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ShareAchievementPage(streakDays: current),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$current', style: s.figure(52)),
                          const SizedBox(width: 6),
                          Text(
                            'hari berturut-turut',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: s.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _Caption(current: current, longest: longest, style: s),
                      const SizedBox(height: 20),
                      _StreakChain(streakData: streakData, style: s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStreakInfoDialog(BuildContext context, DashboardStyle s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: s.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tentang streak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: s.ink,
          ),
        ),
        content: Text(
          'Streak menghitung berapa hari berturut-turut kamu aktif. '
          'Satu hari terhitung saat kamu menyelesaikan latihan atau '
          'mencatat kesehatanmu.\n\n'
          'Di rantai mingguan, hari yang berturut-turut selesai tersambung '
          'menjadi satu.',
          style: TextStyle(
            fontSize: 14,
            color: s.muted,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: DashboardStyle.iris,
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

class _Caption extends StatelessWidget {
  const _Caption({
    required this.current,
    required this.longest,
    required this.style,
  });

  final int current;
  final int longest;
  final DashboardStyle style;

  @override
  Widget build(BuildContext context) {
    final text = current == 0
        ? 'Selesaikan latihan atau catat kesehatanmu hari ini untuk memulai.'
        : current >= longest
            ? 'Ini rekor terpanjangmu.'
            : 'Rekor terpanjangmu $longest hari.';

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: style.muted,
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 19, color: color),
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
    );
  }
}

/// Rantai streak minggu berjalan (Minggu–Sabtu).
class _StreakChain extends StatelessWidget {
  const _StreakChain({required this.streakData, required this.style});

  final StreakData? streakData;
  final DashboardStyle style;

  static const _dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  static const double _chainHeight = 26;

  List<DayStatus> _statuses(DateTime startOfWeek, DateTime today) {
    final byDate = <String, String>{
      for (final d in streakData?.calendar ?? const <CalendarDay>[])
        d.date.length >= 10 ? d.date.substring(0, 10) : d.date: d.status,
    };

    return List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      final key = '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';

      if (byDate[key] == 'completed') return DayStatus.done;
      if (DateUtils.isSameDay(day, today)) return DayStatus.today;
      return day.isAfter(today) ? DayStatus.future : DayStatus.missed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final statuses = _statuses(startOfWeek, today);

    return Semantics(
      label: 'Rantai streak minggu ini: '
          '${statuses.where((d) => d == DayStatus.done).length} dari 7 hari selesai',
      child: Column(
        children: [
          SizedBox(
            height: _chainHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChainPainter(statuses: statuses, style: style),
                  ),
                ),
                Row(
                  children: [
                    for (final status in statuses)
                      Expanded(
                        child: status == DayStatus.done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayLabel(
                    label: _dayLabels[i],
                    date: startOfWeek.add(Duration(days: i)).day,
                    isToday: statuses[i] == DayStatus.today ||
                        DateUtils.isSameDay(
                          startOfWeek.add(Duration(days: i)),
                          today,
                        ),
                    isFuture: statuses[i] == DayStatus.future,
                    style: style,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.label,
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.style,
  });

  final String label;
  final int date;
  final bool isToday;
  final bool isFuture;
  final DashboardStyle style;

  @override
  Widget build(BuildContext context) {
    final color = isToday
        ? DashboardStyle.iris
        : isFuture
            ? style.faint
            : style.muted;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '$date',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ChainPainter extends CustomPainter {
  _ChainPainter({required this.statuses, required this.style});

  final List<DayStatus> statuses;
  final DashboardStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / statuses.length;
    final cy = size.height / 2;
    final r = size.height / 2;
    double cx(int i) => cell * (i + 0.5);

    // Benang dasar yang menghubungkan seluruh minggu.
    canvas.drawLine(
      Offset(cx(0), cy),
      Offset(cx(statuses.length - 1), cy),
      Paint()
        ..color = style.track
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Hari yang selesai berturut-turut digabung menjadi satu kapsul.
    final chainPaint = Paint()
      ..shader = DashboardStyle.chainGradient
          .createShader(Offset.zero & size);

    var i = 0;
    while (i < statuses.length) {
      if (statuses[i] != DayStatus.done) {
        i++;
        continue;
      }
      final start = i;
      while (i + 1 < statuses.length && statuses[i + 1] == DayStatus.done) {
        i++;
      }
      canvas.drawRRect(
        RRect.fromLTRBR(
          cx(start) - r,
          0,
          cx(i) + r,
          size.height,
          Radius.circular(r),
        ),
        chainPaint,
      );
      i++;
    }

    for (var d = 0; d < statuses.length; d++) {
      final center = Offset(cx(d), cy);
      switch (statuses[d]) {
        case DayStatus.done:
          break;
        case DayStatus.today:
          canvas.drawCircle(center, r - 1, Paint()..color = style.card);
          canvas.drawCircle(
            center,
            r - 2,
            Paint()
              ..color = DashboardStyle.iris
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        case DayStatus.missed:
          canvas.drawCircle(center, 4, Paint()..color = style.faint);
        case DayStatus.future:
          canvas.drawCircle(center, 6, Paint()..color = style.card);
          canvas.drawCircle(
            center,
            5,
            Paint()
              ..color = style.track
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_ChainPainter old) =>
      old.style.isDark != style.isDark ||
      !_listEquals(old.statuses, statuses);

  static bool _listEquals(List<DayStatus> a, List<DayStatus> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
