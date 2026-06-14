import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/sleep_today_model.dart';
import 'package:mobile/models/sleep_weekly_summary_model.dart';
import 'package:mobile/pages/catat_tidur_page.dart';
import 'package:mobile/pages/riwayat_tidur_page.dart';
import 'package:mobile/pages/sleep/widgets/hasil_skor_tidur_dialog.dart';
import 'package:mobile/pages/sleep/widgets/sleep_dashboard_skeleton.dart';
import 'package:mobile/services/sleep_service.dart';

const _kPrimary = Color(0xFF7C3AED);
const _kDark = Color(0xFF1F1235);
const _kGrey = Color(0xFF9CA3AF);
const _kBg = Color(0xFFF8F9FB);
const _kGreen = Color(0xFF22C55E);
const _kCardShadow = Color(0x14000000);
const _kToggleBg = Color(0xFFEDE9FE);

class SleepDashboardPage extends StatefulWidget {
  const SleepDashboardPage({super.key});

  @override
  State<SleepDashboardPage> createState() => _SleepDashboardPageState();
}

class _SleepDashboardPageState extends State<SleepDashboardPage> {
  final SleepService _sleepService = SleepService();

  String _selectedPeriod = 'hari';
  SleepTodayModel? _hariIniData;
  SleepWeeklySummaryModel? _mingguIniData;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (_selectedPeriod == 'hari') {
        final results = await Future.wait([
          _sleepService.fetchToday(),
          _sleepService.fetchWeeklySummary(),
        ]);
        if (!mounted) return;
        setState(() {
          _hariIniData = results[0] as SleepTodayModel;
          _mingguIniData = results[1] as SleepWeeklySummaryModel;
        });
      } else {
        final weekly = await _sleepService.fetchWeeklySummary();
        if (!mounted) return;
        setState(() => _mingguIniData = weekly);
      }
    } on SleepServiceException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Gagal memuat data. Coba lagi.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data. Coba lagi.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCatatTidur() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CatatTidurPage()),
    );
    if (saved == true && mounted) {
      await _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _kDark,
        ),
        title: const Text(
          'Pelacakan Tidur',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Center(child: _buildPeriodToggle()),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const RiwayatTidurPage(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Lihat Riwayat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _kToggleBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Hari Ini', 'hari'),
          _buildToggleButton('Minggu Ini', 'minggu'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String value) {
    final isActive = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod == value) return;
        setState(() => _selectedPeriod = value);
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _kGrey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _openTodayDetail() async {
    final logId = _hariIniData?.sleepLogId;
    if (logId == null || logId <= 0) {
      await _openCatatTidur();
      return;
    }

    BuildContext? loadingContext;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingContext = dialogContext;
        return const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(color: _kPrimary),
          ),
        );
      },
    );
    await Future<void>.delayed(Duration.zero);

    try {
      final result = await _sleepService.fetchSleepLogDetail(logId);
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      await showHasilSkorTidurDialog(context, result.toDataMap());
    } on SleepServiceException catch (e) {
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, st) {
      debugPrint('SleepDashboardPage._openTodayDetail: $e\n$st');
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail tidur')),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SleepDashboardSkeleton();
    }

    if (_loadError != null && _mingguIniData == null && _hariIniData == null) {
      return _ErrorView(
        message: _loadError!,
        onRetry: _fetchData,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _selectedPeriod == 'hari'
          ? _HariIniContent(
              key: const ValueKey('hari'),
              today: _hariIniData,
              weekly: _mingguIniData,
              onCatatSekarang: _openCatatTidur,
              onLihatDetail: _openTodayDetail,
            )
          : _MingguIniContent(
              key: const ValueKey('minggu'),
              weekly: _mingguIniData,
              onCatatSekarang: _openCatatTidur,
            ),
    );
  }
}

class _HariIniContent extends StatelessWidget {
  const _HariIniContent({
    super.key,
    required this.today,
    required this.weekly,
    required this.onCatatSekarang,
    required this.onLihatDetail,
  });

  final SleepTodayModel? today;
  final SleepWeeklySummaryModel? weekly;
  final VoidCallback onCatatSekarang;
  final VoidCallback onLihatDetail;

  @override
  Widget build(BuildContext context) {
    final hasToday = today?.hasData ?? false;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasToday)
            _EmptyDataCard(
              message: 'Belum ada data tidur hari ini',
              onCatatSekarang: onCatatSekarang,
            )
          else
            Column(
              children: [
                _SleepScoreCard(
                  title: 'Skor Tidur Hari Ini',
                  score: today!.score ?? 0,
                  category: today!.category ?? '-',
                  message: today!.categoryMessage ?? '',
                  showDetailLink: true,
                  onLihatDetail: onLihatDetail,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Durasi Tidur',
                        value: today!.sleepDuration ?? '-',
                        icon: Icons.bedtime_rounded,
                        iconBg: _kToggleBg,
                        iconColor: _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Tidur',
                        value: today!.sleepTime ?? '-',
                        icon: Icons.nightlight_round,
                        iconBg: _kToggleBg,
                        iconColor: _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Bangun',
                        value: today!.wakeTime ?? '-',
                        icon: Icons.wb_sunny_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),
          const Text(
            'Ringkasan Minggu Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 12),
          _WeeklySummaryCard(weekly: weekly),
        ],
      ),
    );
  }
}

class _MingguIniContent extends StatelessWidget {
  const _MingguIniContent({
    super.key,
    required this.weekly,
    required this.onCatatSekarang,
  });

  final SleepWeeklySummaryModel? weekly;
  final VoidCallback onCatatSekarang;

  @override
  Widget build(BuildContext context) {
    final hasWeekly = weekly?.hasData ?? false;

    if (!hasWeekly) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: _EmptyDataCard(
          message: 'Belum ada data minggu ini',
          onCatatSekarang: onCatatSekarang,
        ),
      );
    }

    final w = weekly!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SleepScoreCard(
            title: 'Rata-rata Skor Minggu Ini',
            score: w.averageScore ?? 0,
            category: w.averageCategory ?? '-',
            message: w.averageCategoryMessage ?? '',
            showDetailLink: false,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                  label: 'Rata-rata Durasi',
                  value: w.averageDuration ?? '-',
                  icon: Icons.bedtime_rounded,
                  iconBg: _kToggleBg,
                  iconColor: _kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatMiniCard(
                  label: 'Rata-rata Tidur',
                  value: w.averageSleepTime ?? '-',
                  icon: Icons.nightlight_round,
                  iconBg: _kToggleBg,
                  iconColor: _kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatMiniCard(
                  label: 'Rata-rata Bangun',
                  value: w.averageWakeTime ?? '-',
                  icon: Icons.wb_sunny_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Ringkasan Minggu Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 12),
          _WeeklySummaryCard(weekly: w),
        ],
      ),
    );
  }
}

class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({
    required this.message,
    required this.onCatatSekarang,
  });

  final String message;
  final VoidCallback onCatatSekarang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 64,
            color: _kPrimary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onCatatSekarang,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Catat Sekarang',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepScoreCard extends StatelessWidget {
  const _SleepScoreCard({
    required this.title,
    required this.score,
    required this.category,
    required this.message,
    required this.showDetailLink,
    this.onLihatDetail,
  });

  final String title;
  final int score;
  final String category;
  final String message;
  final bool showDetailLink;
  final VoidCallback? onLihatDetail;

  @override
  Widget build(BuildContext context) {
    final progress = (score.clamp(0, 100)) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: _kToggleBg,
                        color: _kPrimary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kGrey,
                        height: 1.4,
                      ),
                    ),
                    if (showDetailLink) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: onLihatDetail,
                        child: const Text(
                          'Lihat Detail >',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({this.weekly});

  final SleepWeeklySummaryModel? weekly;

  Color _qualityColor(String? color) {
    return switch (color) {
      'green' => _kGreen,
      'orange' => const Color(0xFFF59E0B),
      'red' => const Color(0xFFEF4444),
      _ => _kGrey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = weekly;
    final hasData = summary?.hasData ?? false;

    if (!hasData || summary == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: _kCardShadow,
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Belum ada ringkasan mingguan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kGrey,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _WeeklyStatColumn(
                    label: 'Rata-rata Tidur',
                    value: summary.averageDuration ?? '-',
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                Expanded(
                  child: _WeeklyStatColumn(
                    label: 'Utang Tidur',
                    value: summary.totalDebt,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                Expanded(
                  child: _WeeklyStatColumn(
                    label: 'Kualitas Tidur',
                    value: summary.qualityLabel,
                    valueColor: _qualityColor(summary.qualityColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: summary.chart.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data grafik',
                      style: TextStyle(color: _kGrey, fontSize: 13),
                    ),
                  )
                : LineChart(_buildChartData(summary.chart)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<SleepChartDay> chart) {
    final spots = <FlSpot>[];
    final dayLabels = <String>[];

    for (var i = 0; i < chart.length; i++) {
      dayLabels.add(chart[i].day);
      final score = chart[i].score;
      if (score != null) {
        spots.add(FlSpot(i.toDouble(), score.toDouble()));
      }
    }

    final scores = chart
        .map((e) => e.score)
        .whereType<int>()
        .toList();

    final maxY = scores.isEmpty
        ? 100.0
        : (scores.reduce((a, b) => a > b ? a : b) + 10).toDouble();

    return LineChartData(
      minY: 0,
      maxY: maxY.clamp(50, 120),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: Color(0xFFF3F4F6),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= dayLabels.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dayLabels[i],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _kGrey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _kPrimary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: _kPrimary,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _kPrimary.withValues(alpha: 0.25),
                _kPrimary.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyStatColumn extends StatelessWidget {
  const _WeeklyStatColumn({
    required this.label,
    required this.value,
    this.valueColor = _kDark,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: _kGrey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

