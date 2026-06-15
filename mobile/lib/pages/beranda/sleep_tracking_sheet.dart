import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/theme/app_colors.dart';

class SleepTrackingSheet extends StatefulWidget {
  const SleepTrackingSheet({super.key});

  @override
  State<SleepTrackingSheet> createState() => _SleepTrackingSheetState();
}

class _SleepTrackingSheetState extends State<SleepTrackingSheet> {
  bool _isTracking = false;
  DateTime? _startTime;
  Duration _sleepDuration = Duration.zero;
  Timer? _timer;

  void _toggleTracking() {
    if (_isTracking) {
      // Stop tracking
      setState(() {
        _isTracking = false;
        _timer?.cancel();
      });
    } else {
      // Start tracking
      setState(() {
        _isTracking = true;
        _startTime = DateTime.now();
        _sleepDuration = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        setState(() {
          _sleepDuration = DateTime.now().difference(_startTime!);
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.only(right: 16, top: 4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: textPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelacakan Tidur',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Dapatkan wawasan tentang pola tidur Anda',
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Sleep Status Cards
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? darkBorder : lightBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: textPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tidur Dimulai Pada',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _startTime != null
                              ? DateFormat('hh:mm a').format(_startTime!)
                              : '--:--',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Estimasi Durasi Tidur',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_sleepDuration.inHours}j ${_sleepDuration.inMinutes.remainder(60)}m',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Diperbarui otomatis',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),
              
              const SizedBox(height: 36),
              
               // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(
                    _isTracking ? Icons.stop_rounded : Icons.dark_mode_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    _isTracking ? 'Hentikan Pelacakan' : 'Mulai Pelacakan Tidur',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : const Color(0xFFA855F7), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Center(
                child: Text(
                  'Letakkan ponsel di meja samping tempat tidur dan bersantailah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

}
