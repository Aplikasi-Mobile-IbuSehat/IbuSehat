import 'package:flutter/material.dart';

class WaktuLatihanCard extends StatelessWidget {
  const WaktuLatihanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Waktu Latihan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1235),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '0/25 mnt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1235),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fitness_center, color: Colors.deepPurple.shade300, size: 24),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          // Middle Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Target\n25 mnt',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1235),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Positioned(
                      top: 6,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDayDot('S'),
                        _buildDayDot('R'),
                        _buildDayDot('K'),
                        _buildDayDot('J'),
                        _buildDayDot('S'),
                        _buildDayDot('M'),
                        _buildDayDot('HARI INI', isToday: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          // Bottom Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Rata-Rata Mingguan',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1F1235), fontWeight: FontWeight.w600),
                ),
                Text(
                  '0 mnt',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F1235)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(String label, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isToday ? const Color(0xFF1F1235) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
