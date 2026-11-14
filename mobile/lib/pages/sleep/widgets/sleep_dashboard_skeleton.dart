import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class SleepDashboardSkeleton extends StatelessWidget {
  const SleepDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? darkBorder : const Color(0xFFE5E7EB);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _box(height: 44, width: 220, radius: 30, color: skeletonColor),
          ),
          const SizedBox(height: 16),
          _box(height: 140, radius: 20, color: skeletonColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _box(height: 96, radius: 16, color: skeletonColor)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 96, radius: 16, color: skeletonColor)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 96, radius: 16, color: skeletonColor)),
            ],
          ),
          const SizedBox(height: 24),
          _box(height: 18, width: 180, radius: 8, color: skeletonColor),
          const SizedBox(height: 12),
          _box(height: 220, radius: 20, color: skeletonColor),
        ],
      ),
    );
  }

  Widget _box({
    required double height,
    double? width,
    double radius = 12,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
