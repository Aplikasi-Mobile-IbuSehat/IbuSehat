import 'package:flutter/material.dart';

/// Dark bottom stats: GPS strip + Waktu | Pace | Jarak.
class StatsPanel extends StatelessWidget {
  const StatsPanel({
    super.key,
    required this.gpsAcquired,
    required this.timeText,
    required this.paceText,
    required this.distanceText,
  });

  final bool gpsAcquired;
  final String timeText;
  final String paceText;
  final String distanceText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: gpsAcquired
                ? const Color(0xFF14532D)
                : const Color(0xFF422006),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gpsAcquired ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 18,
                color: gpsAcquired
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFFDE047),
              ),
              const SizedBox(width: 8),
              Text(
                gpsAcquired ? 'GPS Didapat' : 'Mencari GPS...',
                style: TextStyle(
                  color: gpsAcquired
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFDE047),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatColumn(
              value: timeText,
              label: 'Waktu',
              unit: '',
            ),
            _StatColumn(
              value: paceText,
              label: 'Pace rata2',
              unit: '(/km)',
            ),
            _StatColumn(
              value: distanceText,
              label: 'Jarak',
              unit: '(km)',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.unit,
  });

  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit.isEmpty ? label : '$label $unit',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
