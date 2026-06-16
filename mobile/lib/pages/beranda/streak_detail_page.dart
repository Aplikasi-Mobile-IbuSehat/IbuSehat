import 'package:flutter/material.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';

class StreakDetailPage extends StatelessWidget {
  const StreakDetailPage({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  static const _bgColor = Color(0xFFF8F8FF);
  static const _titleColor = Color(0xFF1A1A2E);
  static const _mutedColor = Color(0xFF9E9E9E);
  static const _primary = Color(0xFF6C4DFF);

  DateTime get _displayMonth => DateTime.now();

  String get _selectedMonthLabel => _formatMonthLabel(_displayMonth);

  String get _longestStreakRange => '—';

  int get _activeDaysThisMonth => 0;

  int get _totalDaysInMonth =>
      DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

  int get _totalActivities => 0;

  List<_StreakCalendarDay> get _calendarDays =>
      _buildCalendarDays(_displayMonth);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: _titleColor,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Detail Streak',
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 20),
              _buildStreakSummary(context),
              const SizedBox(height: 20),
              _buildStreakHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9B59B6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$currentStreak Hari',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9500),
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Konsisten selama $currentStreak hari berturut-turut',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 4,
            child: Icon(
              Icons.emoji_events,
              size: 80,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Material(
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share_outlined,
                size: 16,
                color: _primary,
              ),
              SizedBox(width: 4),
              Text(
                'Bagikan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Ringkasan Streak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                ),
              ),
            ),
            _buildShareButton(context),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF7C3AED),
              label: 'Streak Aktif',
              value: '$currentStreak Hari',
              valueColor: const Color(0xFF7C3AED),
              sublabel: 'Saat ini',
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              iconBgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF2196F3),
              label: 'Streak Terpanjang',
              value: '$longestStreak Hari',
              valueColor: const Color(0xFF2196F3),
              sublabel: _longestStreakRange,
            ),
            _buildStatCard(
              icon: Icons.calendar_month,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
              label: 'Hari Aktif Bulan Ini',
              value: '$_activeDaysThisMonth Hari',
              valueColor: const Color(0xFF4CAF50),
              sublabel: 'dari $_totalDaysInMonth hari',
            ),
            _buildStatCard(
              icon: Icons.show_chart,
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF7C3AED),
              label: 'Total Aktivitas',
              value: '$_totalActivities',
              valueColor: const Color(0xFF7C3AED),
              sublabel: 'Sejak bergabung',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _mutedColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(fontSize: 10, color: _mutedColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHistory() {
    final days = _calendarDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Streak',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _titleColor,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    _selectedMonthLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            return _buildDayCell(days[index]);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegend(
              color: const Color(0xFF4CAF50),
              bgColor: const Color(0xFFE8F5E9),
              label: 'Aktivitas dilakukan',
            ),
            _buildLegend(
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFEDE7F6),
              label: 'Dalam streak aktif',
            ),
            _buildLegend(
              color: _mutedColor,
              bgColor: const Color(0xFFF5F5F5),
              label: 'Tidak aktif',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(_StreakCalendarDay day) {
    if (day.date == null || day.dayNumber == null) {
      return const SizedBox();
    }

    final isOutsideMonth = day.date!.month != _displayMonth.month;
    final textColor =
        isOutsideMonth ? _mutedColor.withValues(alpha: 0.6) : _titleColor;

    Color bgColor;
    Widget? iconWidget;

    switch (day.status) {
      case 'activity':
        bgColor = const Color(0xFFE8F5E9);
        iconWidget = const Icon(
          Icons.check_circle,
          color: Color(0xFF4CAF50),
          size: 14,
        );
      case 'streak':
        bgColor = const Color(0xFFEDE7F6);
        iconWidget = const Icon(
          Icons.check_circle,
          color: Color(0xFF7C3AED),
          size: 14,
        );
      default:
        bgColor = const Color(0xFFF5F5F5);
        iconWidget = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.dayNumber}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (iconWidget != null) ...[
            const SizedBox(height: 2),
            iconWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required Color bgColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: color, size: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _mutedColor),
        ),
      ],
    );
  }

  static String _formatMonthLabel(DateTime month) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  static List<_StreakCalendarDay> _buildCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = first.weekday % 7;
    final days = <_StreakCalendarDay>[];

    for (var i = leadingBlanks; i > 0; i--) {
      final date = first.subtract(Duration(days: i));
      days.add(
        _StreakCalendarDay(
          date: date,
          dayNumber: date.day,
        ),
      );
    }

    for (var d = 1; d <= daysInMonth; d++) {
      days.add(
        _StreakCalendarDay(
          date: DateTime(month.year, month.month, d),
          dayNumber: d,
          status: 'inactive',
        ),
      );
    }

    var trailing = 1;
    while (days.length % 7 != 0) {
      final date = DateTime(month.year, month.month + 1, trailing);
      days.add(
        _StreakCalendarDay(
          date: date,
          dayNumber: date.day,
        ),
      );
      trailing++;
    }

    return days;
  }
}

class _StreakCalendarDay {
  const _StreakCalendarDay({
    this.date,
    this.dayNumber,
    this.status,
  });

  final DateTime? date;
  final int? dayNumber;
  final String? status;
}

