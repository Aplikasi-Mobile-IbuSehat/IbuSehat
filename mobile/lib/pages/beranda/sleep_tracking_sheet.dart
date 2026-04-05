import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FF),
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
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1E293B),
                        size: 28,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelacakan Tidur',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Dapatkan wawasan tentang pola tidur Anda',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9333EA),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF9333EA),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tidur Dimulai Pada',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _startTime != null
                              ? DateFormat('hh:mm a').format(_startTime!)
                              : '--:--',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Estimasi Durasi Tidur',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_sleepDuration.inHours}j ${_sleepDuration.inMinutes.remainder(60)}m',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Diperbarui otomatis',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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
                    backgroundColor: _isTracking ? const Color(0xFFEF4444) : const Color(0xFF6128E6), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Center(
                child: Text(
                  'Letakkan ponsel di meja samping tempat tidur dan bersantailah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9333EA),
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
