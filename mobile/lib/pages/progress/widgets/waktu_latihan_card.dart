import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class WaktuLatihanCard extends StatelessWidget {
  const WaktuLatihanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    const purple = Color(0xFF7C3AED);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
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
                  children: [
                    Text(
                      'Waktu Latihan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0/25 mnt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x227C3AED) : const Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: purple,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          // Middle Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Target\n25 mnt',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
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
                        color: border,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDayDot('S', textPrimary, textSecondary, border),
                        _buildDayDot('R', textPrimary, textSecondary, border),
                        _buildDayDot('K', textPrimary, textSecondary, border),
                        _buildDayDot('J', textPrimary, textSecondary, border),
                        _buildDayDot('S', textPrimary, textSecondary, border),
                        _buildDayDot('M', textPrimary, textSecondary, border),
                        _buildDayDot('HARI INI', textPrimary, textSecondary, border, isToday: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: border, height: 1),
          // Bottom Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rata-Rata Mingguan',
                  style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  '0 mnt',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(
    String label,
    Color textPrimary,
    Color textSecondary,
    Color border, {
    bool isToday = false,
  }) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isToday ? textPrimary : textSecondary,
          ),
        ),
      ],
    );
  }
}
