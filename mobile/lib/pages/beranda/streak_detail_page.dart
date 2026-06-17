import 'package:flutter/material.dart';
import 'package:mobile/pages/beranda/share_achievement_page.dart';
import 'package:mobile/services/streak_service.dart';
import 'package:mobile/models/streak_models.dart';

class StreakDetailPage extends StatefulWidget {
  const StreakDetailPage({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  @override
  State<StreakDetailPage> createState() => _StreakDetailPageState();
}

class _StreakDetailPageState extends State<StreakDetailPage> {
  StreakData? _streakData;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  
  int get currentStreak => _streakData?.streakActive ?? 0;

  static const _bgColor = Color(0xFFF8F8FF);
  static const _titleColor = Color(0xFF1A1A2E);
  static const _mutedColor = Color(0xFF9E9E9E);
  static const _primary = Color(0xFF6C4DFF);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await StreakService().getStreakData(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      if (mounted) {
        setState(() {
          _streakData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching streak data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _fetchData();
  }

  String get _selectedMonthLabel => _formatMonthLabel(_selectedMonth);

  String get _longestStreakRange => '—';

  int get _activeDaysThisMonth => _streakData?.hariAktifBulanIni ?? 0;

  int get _totalDaysInMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

  int get _totalActivities => _streakData?.totalAktivitas ?? 0;

  List<_StreakCalendarDay> get _calendarDays =>
      _buildCalendarDays(_selectedMonth);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        body: const Center(
          child: CircularProgressIndicator(
            color: _primary,
          ),
        ),
      );
    }

    final currentStreak = _streakData?.streakActive ?? widget.currentStreak;
    final longestStreak = _streakData?.streakLongest ?? widget.longestStreak;

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
              value: '${_streakData?.streakActive ?? 0} Hari',
              valueColor: const Color(0xFF7C3AED),
              sublabel: 'Saat ini',
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              iconBgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF2196F3),
              label: 'Streak Terpanjang',
              value: '${_streakData?.streakLongest ?? 0} Hari',
              valueColor: const Color(0xFF2196F3),
              sublabel: _longestStreakRange,
            ),
            _buildStatCard(
              icon: Icons.calendar_month,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
              label: 'Hari Aktif Bulan Ini',
              value: '${_streakData?.hariAktifBulanIni ?? 0} Hari',
              valueColor: const Color(0xFF4CAF50),
              sublabel: 'dari $_totalDaysInMonth hari',
            ),
            _buildStatCard(
              icon: Icons.show_chart,
              iconBgColor: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF7C3AED),
              label: 'Total Aktivitas',
              value: '${_streakData?.totalAktivitas ?? 0}',
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
            Row(
              children: [
                GestureDetector(
                  onTap: () => _changeMonth(-1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.chevron_left, size: 20, color: _titleColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedMonthLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _changeMonth(1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.chevron_right, size: 20, color: _titleColor),
                  ),
                ),
              ],
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

    final isOutsideMonth = day.date!.month != _selectedMonth.month;
    final textColor =
        isOutsideMonth ? _mutedColor.withValues(alpha: 0.6) : _titleColor;

    // Find matching calendar day from API data
    CalendarDay? calendarDay;
    if (_streakData != null) {
      try {
        calendarDay = _streakData!.calendar.firstWhere(
          (cd) {
            final cdDate = DateTime.parse(cd.date);
            return cdDate.year == day.date!.year &&
                   cdDate.month == day.date!.month &&
                   cdDate.day == day.date!.day;
          },
        );
      } catch (e) {
        // No matching day found
      }
    }

    Color bgColor;
    Widget? iconWidget;

    if (calendarDay != null) {
      if (calendarDay.status == 'completed') {
        // Check if it's part of current unbroken streak
        // For simplicity, assume purple if it's recent completed
        // You could add more logic here to check if streak was broken
        bgColor = const Color(0xFFEDE7F6);
        iconWidget = const Icon(
          Icons.check_circle,
          color: Color(0xFF7C3AED),
          size: 14,
        );
      } else if (calendarDay.status == 'today') {
        bgColor = const Color(0xFFF5F5F5);
        iconWidget = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
          ),
        );
      } else if (calendarDay.status == 'missed') {
        bgColor = const Color(0xFFF5F5F5);
        iconWidget = null;
      } else {
        bgColor = const Color(0xFFF5F5F5);
        iconWidget = null;
      }
    } else {
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
          status: null,
        ),
      );
    }

    for (var d = 1; d <= daysInMonth; d++) {
      days.add(
        _StreakCalendarDay(
          date: DateTime(month.year, month.month, d),
          dayNumber: d,
          status: null,
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
          status: null,
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

