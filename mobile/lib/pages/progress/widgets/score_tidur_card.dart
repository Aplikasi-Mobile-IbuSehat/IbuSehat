import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class ScoreTidurCard extends StatelessWidget {
  const ScoreTidurCard({super.key});

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
          Text(
            '--',
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
            '--',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
