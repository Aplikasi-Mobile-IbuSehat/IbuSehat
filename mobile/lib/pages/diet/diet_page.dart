import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/pages/diet/add_food_page.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/pages/diet/water_intake_page.dart';
import 'package:mobile/widgets/app_background.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  // MOCK DATA
  int _waterIntakeMl = 500;
  final int waterGoalMl = 2500;

  final List<Food> _foodLog = [
    Food(id: '1', name: 'Alpukat', weight: 100, kcal: 160, protein: 2, fat: 15, carbs: 9),
    Food(id: '2', name: 'Telur Rebus', weight: 50, kcal: 78, protein: 6, fat: 5, carbs: 0.6),
  ];

  final List<Supplement> _supplements = [
    Supplement(
        id: 's1',
        name: 'Vitamin D',
        description: 'Setelah sarapan',
        reminderTime: const TimeOfDay(hour: 8, minute: 0)),
    Supplement(
        id: 's2',
        name: 'Kalsium',
        description: 'Sebelum tidur',
        reminderTime: const TimeOfDay(hour: 21, minute: 0)),
  ];

  @override
  Widget build(BuildContext context) {
    double totalKcal = _foodLog.fold(0, (sum, item) => sum + item.kcal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Diet & Nutrisi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(child: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Today's Summary (Calories)
            _buildSummaryCard(totalKcal),
            const SizedBox(height: 28),

            // Section header
            _buildSectionHeader('Daftar Makanan', '+ Tambah', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AddFoodPage()));
            }),
            const SizedBox(height: 12),
            _buildFoodLog(),
            const SizedBox(height: 28),

            // Water Intake
            _buildSectionHeader('Asupan Air', null, null),
            const SizedBox(height: 12),
            _buildWaterTracker(),
            const SizedBox(height: 28),

            // Supplement
            _buildSectionHeader('Suplemen Saya', '+ Tambah', () {}),
            const SizedBox(height: 12),
            _buildSupplementList(),
          ],
        ),
      ))),
    );
  }


  Widget _buildSectionHeader(String title, String? actionLabel, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            letterSpacing: -0.3,
          ),
        ),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(double totalKcal) {
    const double targetKcal = 2000;
    final double progress = (totalKcal / targetKcal).clamp(0.0, 1.0);
    final double remaining = (targetKcal - totalKcal).clamp(0, targetKcal);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFB084F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalori Hari Ini',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalKcal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -2),
                  ),
                  const Text(
                    'kkal',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Sisa', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text(
                          '${remaining.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
                        ),
                        const Text('kkal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${totalKcal.toStringAsFixed(0)} kkal dikonsumsi',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                'Target ${targetKcal.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLog() {
    if (_foodLog.isEmpty) {
      return _buildEmptyState(Icons.restaurant_menu_rounded, 'Belum ada makanan dicatat');
    }

    return Container(
      height: 200, // Fixed height for scrollable box
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
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _foodLog.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final Food food = _foodLog[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FoodDetailPage(food: food)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1F1235))),
                        const SizedBox(height: 2),
                        Text('${food.weight.toStringAsFixed(0)} g',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '${food.kcal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1235)),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterTracker() {
    double progress = (_waterIntakeMl / waterGoalMl).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaterIntakePage(
              currentIntake: _waterIntakeMl,
              goalIntake: waterGoalMl,
              onAddWater: (amount) {
                setState(() {
                  _waterIntakeMl += amount;
                });
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                        'assets/icons/water_glass.svg',
                        height: 28, color: Colors.blue,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_waterIntakeMl ml',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1F1235), letterSpacing: -0.5),
                      ),
                      Text(
                        '/ $waterGoalMl ml',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFFEFF6FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF3B82F6), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementList() {
    if (_supplements.isEmpty) {
      return _buildEmptyState(Icons.medication_outlined, 'Belum ada suplemen');
    }

    return Container(
      height: 200, // Fixed height for scrollable box
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
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _supplements.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final supplement = _supplements[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplement.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1F1235))),
                      if (supplement.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(supplement.description,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (supplement.reminderTime != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        supplement.reminderTime!.format(context),
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                else
                  Icon(Icons.check_rounded,
                      color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
