import 'package:flutter/material.dart';

class LangkahCard extends StatelessWidget {
  const LangkahCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Langkah',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1235),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '--',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1235),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          const Text(
            'Target 10.500',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1235),
            ),
          ),
        ],
      ),
    );
  }
}
