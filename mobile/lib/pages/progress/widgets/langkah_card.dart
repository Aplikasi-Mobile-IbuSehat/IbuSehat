import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class LangkahCard extends StatelessWidget {
  const LangkahCard({super.key});

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
          Text(
            'Langkah',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
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
            'Target 10.500',
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
