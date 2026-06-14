import 'package:flutter/material.dart';

const _kSkeleton = Color(0xFFE5E7EB);

class SleepDashboardSkeleton extends StatelessWidget {
  const SleepDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _box(height: 44, width: 220, radius: 30),
          ),
          const SizedBox(height: 16),
          _box(height: 140, radius: 20),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _box(height: 96, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 96, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: _box(height: 96, radius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _box(height: 18, width: 180, radius: 8),
          const SizedBox(height: 12),
          _box(height: 220, radius: 20),
        ],
      ),
    );
  }

  Widget _box({required double height, double? width, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kSkeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
