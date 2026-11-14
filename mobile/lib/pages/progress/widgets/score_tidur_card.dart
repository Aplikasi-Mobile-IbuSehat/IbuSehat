import 'package:flutter/material.dart';
import 'package:mobile/models/sleep_latest_model.dart';
import 'package:mobile/pages/sleep/sleep_dashboard_page.dart';
import 'package:mobile/services/sleep_service.dart';
import 'package:mobile/theme/app_colors.dart';

class ScoreTidurCard extends StatefulWidget {
  const ScoreTidurCard({super.key});

  @override
  State<ScoreTidurCard> createState() => _ScoreTidurCardState();
}

class _ScoreTidurCardState extends State<ScoreTidurCard> {
  final _sleepService = SleepService();
  SleepLatestModel? _latest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() => _loading = true);
    try {
      final latest = await _sleepService.fetchLatestLog();
      if (!mounted) return;
      setState(() {
        _latest = latest;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latest = const SleepLatestModel(hasData: false);
        _loading = false;
      });
    }
  }

  void _openPelacakanTidur() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const SleepDashboardPage(),
      ),
    ).then((_) {
      if (mounted) _loadLatest();
    });
  }

  String get _scoreText {
    if (_loading) return '…';
    if (_latest?.hasData == true && _latest?.score != null) {
      return '${_latest!.score}';
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    const purple = Color(0xFF7C3AED);

    return GestureDetector(
      onTap: _loading ? null : _openPelacakanTidur,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skor Tidur',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Icon(Icons.chevron_right, color: textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const SizedBox(
                height: 29,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: purple,
                    ),
                  ),
                ),
              )
            else
              Text(
                _scoreText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            const SizedBox(height: 16),
            Divider(color: border, height: 1),
            const SizedBox(height: 12),
            Text(
              'Lihat Detail',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
