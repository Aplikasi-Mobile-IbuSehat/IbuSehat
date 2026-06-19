import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _missingToken = false;
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
        });
        return;
      }

      final d = await ActivityService.fetchSummary();

      if (!mounted) return;

      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint("LangkahCard error: $e\n$st");
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _formatSteps(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k langkah';
    }
    return '$n langkah';
  }

  String _mainStepsLine() {
    if (_loading) {
      return '...';
    }
    if (_missingToken) {
      return '--';
    }
    if (_error != null) {
      return 'Error';
    }
    if (_data == null) {
      return '--';
    }

    final steps = _data!.todayStepsEstimate;
    if (steps == 0) {
      return '0 langkah hari ini';
    }
    return _formatSteps(steps);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

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
                  'Langkah',

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

            Text(
              _mainStepsLine(),

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: border, height: 1),

            const SizedBox(height: 12),
            Text(
              'Target 10.500 langkah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
