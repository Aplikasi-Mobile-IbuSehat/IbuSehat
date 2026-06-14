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

  String _formatSteps(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(1)}k langkah';
    }
    return '$n langkah';
  }

  @override
  Widget build(BuildContext context) {
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
}
