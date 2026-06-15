import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class BeratCard extends StatelessWidget {
  const BeratCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    return Container(
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
                'Berat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                'Maret 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Simple graph mockup
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              children: [
                // Y-axis guidelines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridLine('80'),
                    _buildGridLine('70'),
                    _buildGridLine('60'),
                  ],
                ),
                // X-axis indicators
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 32, // to align with the grid end
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: TextStyle(fontSize: 10, color: textSecondary)),
                      Text('8', style: TextStyle(fontSize: 10, color: textSecondary)),
                      Text('15', style: TextStyle(fontSize: 10, color: textSecondary)),
                      Text('22', style: TextStyle(fontSize: 10, color: textSecondary)),
                    ],
                  ),
                ),
                // Vertical line marker
                Positioned(
                  bottom: 16,
                  right: 35, // approximately near 22
                  child: Container(
                    width: 2,
                    height: 105,
                    color: textPrimary,
                  ),
                ),
                // Point on graph
                Positioned(
                  top: 15,
                  right: 31,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple.shade300, width: 2.5),
                    ),
                  ),
                ),
                // Tooltip
                Positioned(
                  top: -5,
                  right: 17,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C223E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '80 kg',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLine(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
