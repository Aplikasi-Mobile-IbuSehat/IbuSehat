import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/progress_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/models/progress_summary_model.dart';
import 'dart:math' show max;

class KaloriMakananCard extends StatelessWidget {
  // Label hari tetap Senin–Minggu
  static const List<String> _weekLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  const KaloriMakananCard({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final data = progressProvider.summary;
    final nutrition = data?.weekly.nutrition;

    final int todayKkal = nutrition?.today ?? 0;
    final int targetDailyKkal = nutrition?.targetDailyKkal ?? 2067;
    final int average = nutrition?.average ?? 0;
    final List<DailyIntake> daily = nutrition?.daily ?? [];

    final formatter = NumberFormat('#,###', 'id');

    // Hari ini dalam minggu: Senin=0, Selasa=1, ..., Minggu=6
    final int todayWeekday = DateTime.now().weekday - 1;

    // Petakan data API (7 hari terakhir) ke slot minggu tetap
    final List<double> weekData = List.filled(7, 0.0);
    for (int slot = 0; slot <= todayWeekday; slot++) {
      final int daysAgo = todayWeekday - slot;
      final int dataIndex = (daily.length - 1) - daysAgo;
      if (dataIndex >= 0 && dataIndex < daily.length) {
        weekData[slot] = daily[dataIndex].amount.toDouble();
      }
    }

    final double maxY = _calculateMaxY(weekData, targetDailyKkal);

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
                  children: [
                    const Text(
                      'Kalori Makanan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1235),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(todayKkal)}/${formatter.format(targetDailyKkal)} kkal',
                      style: const TextStyle(
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EEFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, color: Color(0xFF8B5CF6), size: 24),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),
          // Middle Content — Bar Chart
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Text(
                      'Target\n${formatter.format(targetDailyKkal)} kkal',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1235),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: daily.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => const Color(0xFF1F1235),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()} kkal',
                                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= 7) {
                                      return const SizedBox.shrink();
                                    }
                                    final isToday = index == todayWeekday;
                                    final isFuture = index > todayWeekday;
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 4,
                                      child: Text(
                                        _weekLabels[index],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isToday
                                              ? const Color(0xFF7C3AED)
                                              : isFuture
                                                  ? Colors.grey.shade300
                                                  : Colors.grey,
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: targetDailyKkal.toDouble(),
                                  color: const Color(0xFFF97316),
                                  strokeWidth: 2,
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 8, bottom: 2),
                                    style: const TextStyle(
                                      color: Color(0xFFF97316),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    labelResolver: (line) => 'Target',
                                  ),
                                ),
                              ],
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              final amount = weekData[index];
                              final isToday = index == todayWeekday;
                              final isFuture = index > todayWeekday;
                              final isEmpty = amount == 0;

                              Color barColor;
                              if (isFuture) {
                                barColor = const Color(0xFFE5E7EB);
                              } else if (isEmpty) {
                                barColor = const Color(0xFFE5E7EB);
                              } else if (isToday) {
                                barColor = const Color(0xFF9F67FF);
                              } else {
                                barColor = const Color(0xFF7C3AED);
                              }

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: isEmpty || isFuture ? 0 : amount,
                                    color: barColor,
                                    borderSide: isToday
                                        ? const BorderSide(color: Color(0xFF7C3AED), width: 1.5)
                                        : const BorderSide(color: Colors.transparent, width: 0),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    backDrawRodData: BackgroundBarChartRodData(show: false),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
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
              children: [
                const Text(
                  'Rata-Rata Mingguan',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1F1235), fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatter.format(average)} kkal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F1235)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<double> data, int target) {
    if (data.every((v) => v == 0)) return target * 1.3;
    final maxData = data.reduce((a, b) => a > b ? a : b);
    return max(target * 1.3, maxData * 1.3);
  }
}
