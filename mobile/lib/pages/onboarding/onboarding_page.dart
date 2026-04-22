import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/app_background.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  static const int _totalSteps = 8;
  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Answers (start as null so nothing is pre-selected)
  Goal? _goal;
  ActivityLevel? _activityLevel;
  DeliveryMethod? _deliveryMethod;
  DateTime? _deliveryDate;

  int? _ageYears;
  int? _heightCm;
  int? _weightKg;
  int? _targetWeightKg;

  // "Touched" flags so wheel pickers don't auto-select until user interacts
  bool _touchedAge = false;
  bool _touchedHeight = false;
  bool _touchedWeight = false;
  bool _touchedTargetWeight = false;

  Future<void> _nextPage() async {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      await AuthService.instance.setOnboardingDone();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: List.generate(_totalSteps, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? const Color(0xFF8B5CF6)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _totalSteps,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0: return _buildStep1();
                      case 1: return _buildStepGoal();
                      case 2: return _buildStepActivity();
                      case 3: return _buildStepDelivery();
                      case 4: return _buildStepAge();
                      case 5: return _buildStepHeight();
                      case 6: return _buildStepWeight();
                      case 7: return _buildStepTargetWeight();
                      default: return const SizedBox.shrink();
                    }
                  },
                ),
              ),

              // Fixed Bottom Navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
                child: Row(
                  children: [
                    // Animated Back Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: _currentStep == 0 ? 0 : 56,
                      height: 56,
                      margin: EdgeInsets.only(right: _currentStep == 0 ? 0 : 12),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _currentStep == 0 ? 0 : 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IconButton(
                            onPressed: _previousPage,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1F1235),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main Action Button
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _nextPage,
                          child: Text(
                            _currentStep == 0 
                                ? "Mulai Sekarang" 
                                : (_currentStep == _totalSteps - 1 ? "Selesai" : "Lanjutkan"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
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
  }

  // ── STEP 1: WELCOME & EDUCATION ───────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 80,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            "Selamat Datang di Ibu Sehat",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1235),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Personalisasi nutrisi dan gaya hidup sehat untuk ibu pasca melahirkan. Kami di sini untuk mendampingimu.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: GOAL (after intro) ────────────────────────────────────────────
  Widget _buildStepGoal() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Target Utama",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1235),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Apa yang ingin kamu capai?",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildGoalCard("Menurunkan Berat Badan", Goal.loseWeight),
                const SizedBox(height: 14),
                _buildGoalCard("Menjaga Berat Badan", Goal.maintainWeight),
                const SizedBox(height: 14),
                _buildGoalCard("Menaikkan Berat Badan", Goal.gainWeight),
                const SizedBox(height: 14),
                _buildGoalCard("Meningkatkan Kesehatan Fisik", Goal.improvePhysicalHealth),
                const SizedBox(height: 14),
                _buildGoalCard("Membentuk Kembali Bentuk Tubuh", Goal.rebuildBodyShape),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 3: ACTIVITY LEVEL ────────────────────────────────────────────────
  Widget _buildStepActivity() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tingkat Aktivitas",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1235),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Pilih tingkat aktivitas harianmu",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _buildActivityCard("Jarang Bergerak (Sedenter)", ActivityLevel.sedentary),
                const SizedBox(height: 14),
                _buildActivityCard("Aktivitas Ringan", ActivityLevel.light),
                const SizedBox(height: 14),
                _buildActivityCard("Aktivitas Sedang", ActivityLevel.moderate),
                const SizedBox(height: 14),
                _buildActivityCard("Sangat Aktif", ActivityLevel.veryActive),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 4: DELIVERY (vertical options) + Relative/Quick Date ─────────────
  Widget _buildStepDelivery() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Riwayat Persalinan",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1235),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Jenis Persalinan",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildDeliveryCard("Normal", DeliveryMethod.normal),
                const SizedBox(height: 12),
                _buildDeliveryCard("Sesar", DeliveryMethod.sesar),
                const SizedBox(height: 28),
                const Text(
                  "Kapan terakhir kali melahirkan?",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildRelativeDateRangeCard(
                  label: "Kurang dari 3 bulan lalu",
                  approxSubtract: const Duration(days: 45),
                ),
                const SizedBox(height: 12),
                _buildRelativeDateRangeCard(
                  label: "3–6 bulan lalu",
                  approxSubtract: const Duration(days: 135),
                ),
                const SizedBox(height: 12),
                _buildRelativeDateRangeCard(
                  label: "6–12 bulan lalu",
                  approxSubtract: const Duration(days: 270),
                ),
                const SizedBox(height: 12),
                _buildRelativeDateRangeCard(
                  label: "1–2 tahun lalu",
                  approxSubtract: const Duration(days: 540),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 5: AGE (wheel picker) ────────────────────────────────────────────
  Widget _buildStepAge() {
    return _buildWheelStep(
      title: "Usia",
      subtitle: "Geser untuk memilih usia (tahun)",
      unit: "tahun",
      min: 13,
      max: 60,
      touched: _touchedAge,
      value: _ageYears,
      onChanged: (v) => setState(() {
        _touchedAge = true;
        _ageYears = v;
      }),
    );
  }

  // ── STEP 6: HEIGHT (wheel picker) ─────────────────────────────────────────
  Widget _buildStepHeight() {
    return _buildWheelStep(
      title: "Tinggi Badan",
      subtitle: "Geser untuk memilih tinggi (cm)",
      unit: "cm",
      min: 120,
      max: 200,
      touched: _touchedHeight,
      value: _heightCm,
      onChanged: (v) => setState(() {
        _touchedHeight = true;
        _heightCm = v;
      }),
    );
  }

  // ── STEP 7: WEIGHT (wheel picker) ─────────────────────────────────────────
  Widget _buildStepWeight() {
    return _buildWheelStep(
      title: "Berat Badan",
      subtitle: "Geser untuk memilih berat (kg)",
      unit: "kg",
      min: 30,
      max: 200,
      touched: _touchedWeight,
      value: _weightKg,
      onChanged: (v) => setState(() {
        _touchedWeight = true;
        _weightKg = v;
      }),
    );
  }

  // ── STEP 8: TARGET WEIGHT (wheel picker) ──────────────────────────────────
  Widget _buildStepTargetWeight() {
    return _buildWheelStep(
      title: "Target Berat Badan",
      subtitle: "Geser untuk memilih target (kg)",
      unit: "kg",
      min: 30,
      max: 200,
      touched: _touchedTargetWeight,
      value: _targetWeightKg,
      onChanged: (v) => setState(() {
        _touchedTargetWeight = true;
        _targetWeightKg = v;
      }),
      nextButtonText: "Selesai",
    );
  }

  // ── REUSABLE WIDGETS ──────────────────────────────────────────────────────

  Widget _buildWheelStep({
    required String title,
    required String subtitle,
    required String unit,
    required int min,
    required int max,
    required bool touched,
    required int? value,
    required ValueChanged<int> onChanged,
    String nextButtonText = "Lanjutkan",
  }) {
    final displayValue = touched && value != null ? "$value $unit" : "Belum dipilih";

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1235),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: touched && value != null ? const Color(0xFF1F1235) : Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _buildIntWheelPicker(
                      min: min,
                      max: max,
                      initialValue: value ?? ((min + max) ~/ 2),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntWheelPicker({
    required int min,
    required int max,
    required int initialValue,
    required ValueChanged<int> onChanged,
  }) {
    final values = List<int>.generate(max - min + 1, (i) => min + i);
    final initialIndex = (initialValue - min).clamp(0, values.length - 1);

    return CupertinoTheme(
      data: const CupertinoThemeData(
        textTheme: CupertinoTextThemeData(
          pickerTextStyle: TextStyle(
            fontSize: 22,
            color: Color(0xFF1F1235),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: CupertinoPicker(
        itemExtent: 44,
        magnification: 1.05,
        squeeze: 1.1,
        useMagnifier: true,
        scrollController: FixedExtentScrollController(initialItem: initialIndex),
        onSelectedItemChanged: (index) => onChanged(values[index]),
        children: values
            .map(
              (v) => Center(
                child: Text(
                  v.toString(),
                ),
              ),
            )
            .toList(),
      ),
    );
  }



  Widget _buildActivityCard(String label, ActivityLevel level) {
    final isSelected = _activityLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _activityLevel = level),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F1235),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(String label, Goal goal) {
    final isSelected = _goal == goal;
    return GestureDetector(
      onTap: () => setState(() => _goal = goal),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F1235),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(String label, DeliveryMethod method) {
    final isSelected = _deliveryMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = method),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1F1235),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRelativeDateRangeCard({
    required String label,
    required Duration approxSubtract,
  }) {
    final candidate = DateTime.now().subtract(approxSubtract);
    final isSelected = _deliveryDate != null &&
        _deliveryDate!.year == candidate.year &&
        _deliveryDate!.month == candidate.month &&
        _deliveryDate!.day == candidate.day;

    return GestureDetector(
      onTap: () => setState(() => _deliveryDate = candidate),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1F1235),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }


}
