import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/pages/diet/add_food_page.dart';
import 'package:mobile/pages/diet/add_supplement_page.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/pages/diet/water_intake_page.dart';
import 'package:mobile/pages/profile/premium_page.dart';
import 'package:mobile/pages/chat/ai_chat_page.dart';
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

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 5;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  final List<Food> _foodLog = [
    Food(id: '1', name: 'Alpukat', weight: 100, kcal: 160, protein: 2, fat: 15, carbs: 9, icon: Icons.eco, color: const Color(0xFF22C55E)),
    Food(id: '2', name: 'Telur Rebus', weight: 50, kcal: 78, protein: 6, fat: 5, carbs: 0.6, icon: Icons.egg, color: const Color(0xFFF59E0B)),
  ];

  final List<Supplement> _supplements = [
    Supplement(
        id: 's1',
        name: 'Vitamin D',
        description: 'Setelah sarapan',
        reminderTime: const TimeOfDay(hour: 8, minute: 0),
        isTaken: true),
    Supplement(
        id: 's2',
        name: 'Kalsium',
        description: 'Sebelum tidur',
        reminderTime: const TimeOfDay(hour: 21, minute: 0),
        isTaken: false),
  ];

  @override
  Widget build(BuildContext context) {
    double totalKcal = _foodLog.fold(0, (sum, item) => sum + item.kcal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 95.0,
              backgroundColor: _isScrolled ? const Color(0xFFF8F9FB) : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _isScrolled ? 1 : 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PremiumPage()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: SvgPicture.asset(
                              'assets/icons/sparkles_premium.svg',
                              width: 24, // Matches the size of message_circle.svg
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/message_circle.svg',
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1F1235),
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AiChatPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                centerTitle: false,
                title: Text(
                  'Diet & Nutrisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1235),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
                    const SizedBox(height: 20),
                    _buildFoodLog(),
                    const SizedBox(height: 28),

                    // Water Intake
                    _buildSectionHeader('Asupan Air', null, null),
                    const SizedBox(height: 20),
                    _buildWaterTracker(),
                    const SizedBox(height: 28),

                    // Supplement
                    _buildSectionHeader('Suplemen Saya', '+ Tambah', () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddSupplementPage()),
                      );
                      if (result != null && result is Supplement) {
                        setState(() {
                          _supplements.add(result);
                        });
                      }
                    }),
                    const SizedBox(height: 20),
                    _buildSupplementList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(20),
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
                        color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                  ),
                  const Text(
                    'kkal',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
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
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
                        ),
                        const Text('kkal', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
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
      height: 200,
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
            onTap: () => _showItemOptionsSheet(context, isFood: true, index: index),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getFoodColor(food),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFoodIcon(food),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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

  void _showTimePickerSheet(BuildContext context, int index) {
    final supplement = _supplements[index];
    TimeOfDay selectedTime = supplement.reminderTime ?? TimeOfDay.now();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final FixedExtentScrollController hourController =
                FixedExtentScrollController(initialItem: selectedTime.hour);
            final FixedExtentScrollController minuteController =
                FixedExtentScrollController(initialItem: selectedTime.minute);

            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40), // Floating bottom margin
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      const Text(
                        'Atur Pengingat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1235),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Dual Wheel Picker (00 : 00)
                      SizedBox(
                        height: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hours
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: hourController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: index, minute: selectedTime.minute);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (context, index) {
                                    bool isSelected = selectedTime.hour == index;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(index.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const Text(
                              ':',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1235),
                              ),
                            ),
                            // Minutes
                            SizedBox(
                              width: 80,
                              child: ListWheelScrollView.useDelegate(
                                controller: minuteController,
                                itemExtent: 45,
                                perspective: 0.005,
                                diameterRatio: 1.2,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  setModalState(() {
                                    selectedTime = TimeOfDay(hour: selectedTime.hour, minute: index);
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, index) {
                                    bool isSelected = selectedTime.minute == index;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade400,
                                        ),
                                        child: Text(index.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _supplements[index] = supplement.copyWith(reminderTime: selectedTime);
                                    });
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
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
          return GestureDetector(
            onTap: () => _showItemOptionsSheet(context, isFood: false, index: index),
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
                      Text(supplement.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1F1235))),
                      const SizedBox(height: 2),
                      Text(
                        (supplement.isTaken ?? false) ? 'Sudah diminum' : 'Belum diminum',
                        style: TextStyle(
                            color: (supplement.isTaken ?? false) 
                                ? const Color(0xFF22C55E) 
                                : Colors.grey.shade500, 
                            fontSize: 12,
                            fontWeight: (supplement.isTaken ?? false) ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                if (supplement.reminderTime != null)
                  GestureDetector(
                    onTap: () => _showTimePickerSheet(context, index),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
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
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _supplements[index] = supplement.copyWith(isTaken: !(supplement.isTaken ?? false));
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (supplement.isTaken ?? false) 
                          ? const Color(0xFF22C55E).withOpacity(0.1) 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (supplement.isTaken ?? false) 
                            ? const Color(0xFF22C55E) 
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: (supplement.isTaken ?? false) 
                          ? const Color(0xFF22C55E) 
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  void _showItemOptionsSheet(BuildContext context, {required bool isFood, required int index}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isFood ? 'Opsi Makanan' : 'Opsi Suplemen',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBottomSheetOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    color: const Color(0xFF1F1235),
                    onTap: () async {
                      Navigator.pop(context);
                      if (isFood) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => FoodDetailPage(food: _foodLog[index])));
                      } else {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddSupplementPage(supplement: _supplements[index])),
                        );
                        if (result != null && result is Supplement) {
                          setState(() {
                            _supplements[index] = result;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBottomSheetOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (isFood) {
                          _foodLog.removeAt(index);
                        } else {
                          _supplements.removeAt(index);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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

  IconData _getFoodIcon(Food food) {
    if (food.icon != null) return food.icon!;
    
    final name = food.name.toLowerCase();
    if (name.contains('ayam') || name.contains('chicken')) return Icons.kebab_dining;
    if (name.contains('telur') || name.contains('egg')) return Icons.egg;
    if (name.contains('nasi') || name.contains('rice')) return Icons.rice_bowl;
    if (name.contains('ikan') || name.contains('fish')) return Icons.set_meal;
    if (name.contains('daging') || name.contains('meat') || name.contains('sapi')) return Icons.lunch_dining;
    if (name.contains('buah') || name.contains('fruit') || name.contains('alpukat')) return Icons.eco;
    if (name.contains('sayur') || name.contains('veggie')) return Icons.grass;
    if (name.contains('susu') || name.contains('milk')) return Icons.water_drop;
    if (name.contains('roti') || name.contains('bread')) return Icons.bakery_dining;
    
    return Icons.restaurant;
  }

  Color _getFoodColor(Food food) {
    if (food.color != null) return food.color!;
    
    final name = food.name.toLowerCase();
    if (name.contains('ayam') || name.contains('chicken')) return const Color(0xFFF97316); // Orange
    if (name.contains('telur') || name.contains('egg')) return const Color(0xFFF59E0B); // Amber
    if (name.contains('nasi') || name.contains('rice')) return const Color(0xFF94A3B8); // Gray/Slate
    if (name.contains('ikan') || name.contains('fish')) return const Color(0xFF0EA5E9); // Sky Blue
    if (name.contains('daging') || name.contains('meat') || name.contains('sapi')) return const Color(0xFFEF4444); // Red
    if (name.contains('buah') || name.contains('fruit') || name.contains('alpukat')) return const Color(0xFF22C55E); // Green
    if (name.contains('sayur') || name.contains('veggie')) return const Color(0xFF10B981); // Emerald
    if (name.contains('susu') || name.contains('milk')) return const Color(0xFF38BDF8); // Light Blue
    if (name.contains('roti') || name.contains('bread')) return const Color(0xFFD97706); // Brownish
    
    return const Color(0xFF8B5CF6); // Default Purple
  }
}
