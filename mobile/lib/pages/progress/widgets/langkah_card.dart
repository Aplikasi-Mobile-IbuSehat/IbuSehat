import 'package:flutter/material.dart';
import 'package:mobile/models/activity_model.dart';
import 'package:mobile/services/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/activity_history_screen.dart';

class LangkahCard extends StatefulWidget {
  const LangkahCard({super.key});

  @override
  State<LangkahCard> createState() => _LangkahCardState();
}

class _LangkahCardState extends State<LangkahCard> {
  ActivitySummaryResponse? _data;
  Object? _error;
  bool _loading = true;
  bool _missingToken = false;
  String _debugLine = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Public refresh for parent widgets if needed.
  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _missingToken = false;
      _debugLine = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _data = null;
          _missingToken = true;
          _loading = false;
          _debugLine = 'LANGKAH: no token in SharedPreferences';
        });
        debugPrint(_debugLine);
        return;
      }

      final d = await ActivityService.fetchSummary();
      if (!mounted) return;
      debugPrint(
        'LANGKAH OK today_steps=${d.todayStepsEstimate} '
        'km=${d.todayDistanceKm} weekly=${d.weeklyChart.length}',
      );
      setState(() {
        _data = d;
        _loading = false;
        _debugLine =
            'OK · steps=${d.todayStepsEstimate} · ${_shortJson(d)}';
      });
    } on LangkahSummaryError catch (e) {
      debugPrint('LangkahCard LangkahSummaryError: ${e.userMessage}');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _debugLine = 'ERR · ${e.userMessage}';
      });
    } catch (e, st) {
      debugPrint('LangkahCard._load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _debugLine = 'ERR · $e';
      });
    }
  }

  String _shortJson(ActivitySummaryResponse d) {
    return 'dist=${d.todayDistanceKm.toStringAsFixed(2)}';
  }

  String _mainStepsLine() {
    if (_loading) return '…';
    if (_missingToken) return '--';
    if (_error != null) {
      if (_error is LangkahSummaryError) {
        return (_error as LangkahSummaryError).userMessage;
      }
      return 'Error';
    }
    if (_data == null) return '--';
    final d = _data!;
    final emptyDay =
        d.todayStepsEstimate == 0 && d.todayDistanceKm == 0;
    if (emptyDay) return '0 langkah hari ini';
    return _formatSteps(d.todayStepsEstimate);
  }

  String _fmtKm(double km) {
    if (km >= 10) return km.toStringAsFixed(1);
    return km.toStringAsFixed(2);
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final latest = _data?.latestActivity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Langkah',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1235),
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Muat ulang',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _load,
                ),
            ],
          ),
          if (_debugLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _debugLine,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _mainStepsLine(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1235),
              letterSpacing: -0.5,
            ),
          ),
          if (!_loading && _error == null && _data != null) ...[
            const SizedBox(height: 4),
            Text(
              'Jarak hari ini: ${_fmtKm(_data!.todayDistanceKm)} km',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          if (latest != null) ...[
            const Text(
              'Aktivitas terakhir',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              latest.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1235),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmtKm(latest.distanceKm)} km · ${_fmtDuration(latest.durationSeconds)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_data != null && _data!.weeklyChart.isNotEmpty) ...[
            const Text(
              'Minggu ini (km)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            _WeeklyBars(days: _data!.weeklyChart),
          ],
          const SizedBox(height: 8),
          const Text(
            'Target 10.500',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1235),
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Record Lari',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1235),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '🏃',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1235),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.2), height: 1),
            const SizedBox(height: 12),
            const Text(
              'Lihat Riwayat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1235),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSteps(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.days});

  final List<WeeklyChartDay> days;

  @override
  Widget build(BuildContext context) {
    final maxKm = days
        .map((d) => d.distanceKm)
        .fold<double>(0.001, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final h = 8 + (d.distanceKm / maxKm) * 40;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h.clamp(8, 48),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
