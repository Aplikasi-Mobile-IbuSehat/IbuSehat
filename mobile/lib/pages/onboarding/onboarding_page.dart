import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/user_profile.dart';
import 'package:mobile/pages/main_page.dart';
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

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Finalize and go to Main Page
      // (Profile persistence can be added later if needed.)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
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
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1(),
                    _buildStepGoal(),
                    _buildStepActivity(),
                    _buildStepDelivery(),
                    _buildStepAge(),
                    _buildStepHeight(),
                    _buildStepWeight(),
                    _buildStepTargetWeight(),
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
          const Spacer(),
          _buildNextButton("Mulai Sekarang"),
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
                const SizedBox(height: 6),
                Text(
                  "Opsional • boleh dilewati",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: _buildBottomButtons("Lanjutkan"),
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
                const SizedBox(height: 6),
                Text(
                  "Opsional • boleh dilewati",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: _buildBottomButtons("Lanjutkan"),
        ),
      ],
    );
  }

  // ── STEP 4: DELIVERY (vertical options) + Relative/Quick Date ─────────────
  Widget _buildStepDelivery() {
    final dateText = _deliveryDate == null
        ? "Belum dipilih"
        : DateFormat('dd MMMM yyyy').format(_deliveryDate!);

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
                const SizedBox(height: 6),
                Text(
                  "Opsional • boleh dilewati",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final initial = _deliveryDate ?? DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF8B5CF6),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() => _deliveryDate = pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: _deliveryDate == null
                                  ? Colors.grey.shade500
                                  : const Color(0xFF1F1235),
                            ),
                          ),
                        ),
                        Text(
                          "Pilih tanggal",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: _buildBottomButtons("Lanjutkan"),
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
                const SizedBox(height: 6),
                Text(
                  "Opsional • boleh dilewati",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: _buildBottomButtons(nextButtonText),
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

  Widget _buildNextButton(String text) {
    return Container(
      width: double.infinity,
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
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2),
        ),
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

  Widget _buildBottomButtons(String nextButtonText) {
    return Row(
      children: [
        // Icon back button
        Container(
          width: 56,
          height: 56,
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
        const SizedBox(width: 12),
        // Continue button
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
                nextButtonText,
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
    );
  }
}
