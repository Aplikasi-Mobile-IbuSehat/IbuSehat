import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'dart:math' as math;

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  State<BMICalculatorPage> createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _waistController = TextEditingController();

  double? _bmi;
  double? _bodyFat;
  double? _whtr;

  String _bmiStatus = '';
  Color _bmiStatusColor = Colors.grey;

  String _whtrStatus = '';
  Color _whtrStatusColor = Colors.grey;

  void _calculateAll() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = double.tryParse(_ageController.text);
    final waist = double.tryParse(_waistController.text);

    final validWeight = weight != null && weight > 0;
    final validHeight = height != null && height > 0;
    final validAge = age != null && age > 0;
    final validWaist = waist != null && waist > 0;

    if (validWeight && validHeight && validAge) {
      setState(() {
        // 1. BMI
        final bmi = weight / math.pow(height / 100, 2);
        _bmi = bmi;
        _updateBMIStatus(bmi);

        // 2. Body Fat % — Deurenberg et al. (1991), wanita
        // BF% = 1.20 × BMI + 0.23 × Age − 5.4
        _bodyFat = 1.20 * bmi + 0.23 * age - 5.4;

        // 3. WHtR (opsional)
        if (validWaist) {
          _whtr = waist / height;
          _updateWHtRStatus(_whtr!);
        } else {
          _whtr = null;
          _whtrStatus = '';
          _whtrStatusColor = Colors.grey;
        }
      });
    }
  }

  void _updateBMIStatus(double bmi) {
    if (bmi < 18.5) {
      _bmiStatus = 'Kekurangan Berat Badan';
      _bmiStatusColor = const Color(0xFF3B82F6);
    } else if (bmi < 25) {
      _bmiStatus = 'Normal (Ideal)';
      _bmiStatusColor = const Color(0xFF10B981);
    } else if (bmi < 30) {
      _bmiStatus = 'Kelebihan Berat Badan';
      _bmiStatusColor = const Color(0xFFF59E0B);
    } else {
      _bmiStatus = 'Obesitas';
      _bmiStatusColor = const Color(0xFFEF4444);
    }
  }

  void _updateWHtRStatus(double whtr) {
    if (whtr < 0.5) {
      _whtrStatus = 'Risiko Rendah / Sehat';
      _whtrStatusColor = const Color(0xFF10B981);
    } else if (whtr < 0.6) {
      _whtrStatus = 'Risiko Meningkat';
      _whtrStatusColor = const Color(0xFFF59E0B);
    } else {
      _whtrStatus = 'Risiko Tinggi';
      _whtrStatusColor = const Color(0xFFEF4444);
    }
  }

  @override
  void initState() {
    super.initState();
    // Tidak ada kalkulasi awal — kartu tetap tampil dengan nilai kosong
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Kalkulator Kesehatan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputSection(isDark),
              const SizedBox(height: 32),
              _buildBMIResultCard(),
              const SizedBox(height: 16),
              _buildBodyFatCard(isDark),
              const SizedBox(height: 16),
              _buildWHtRSection(isDark),
              const SizedBox(height: 32),
              _buildBMITable(isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.9 : 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _buildInputField(
            label: 'Berat Badan',
            controller: _weightController,
            unit: 'Kg',
            isDark: isDark,
            onChanged: (v) => _calculateAll(),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Tinggi Badan',
            controller: _heightController,
            unit: 'Cm',
            isDark: isDark,
            onChanged: (v) => _calculateAll(),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Umur',
            controller: _ageController,
            unit: 'Tahun',
            isDark: isDark,
            onChanged: (v) => _calculateAll(),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Lingkar Pinggang (Opsional)',
            controller: _waistController,
            unit: 'Cm',
            isDark: isDark,
            onChanged: (v) => _calculateAll(),
            isOptional: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required bool isDark,
    required ValueChanged<String> onChanged,
    bool isOptional = false,
  }) {
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkBackground : lightSurface;
    final border = isDark ? darkBorder : const Color(0x0D000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              hintText: isOptional ? 'Kosongkan jika tidak ada' : null,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              suffixText: unit,
              suffixStyle: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── BMI Result Card (existing style) ────────────────────────────────────────
  Widget _buildBMIResultCard() {
    final displayColor = _bmi != null ? _bmiStatusColor : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [displayColor.withValues(alpha: 0.8), displayColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Skor BMI Anda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bmi != null ? _bmi!.toStringAsFixed(1) : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _bmi != null ? _bmiStatus : 'Isi data untuk melihat hasil',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body Fat Percentage Card ────────────────────────────────────────────────
  Widget _buildBodyFatCard(bool isDark) {
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    const accentColor = Color(0xFFEC4899); // pink — wanita

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.9 : 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite_rounded, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimasi Lemak Tubuh',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bodyFat != null ? '${_bodyFat!.toStringAsFixed(2)}%' : '— %',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Body\nFat %',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── WHtR Section ────────────────────────────────────────────────────────────
  Widget _buildWHtRSection(bool isDark) {
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    if (_whtr == null) {
      // Lingkar pinggang tidak diisi — tampilkan pesan saran
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: isDark ? 0.9 : 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tambahkan lingkar pinggang untuk analisis risiko lemak perut yang lebih akurat.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // WHtR tersedia
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.9 : 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _whtrStatusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.monitor_weight_outlined, color: _whtrStatusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rasio Pinggang-Tinggi (WHtR)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _whtr != null ? _whtr!.toStringAsFixed(2) : '—',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _whtrStatusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _whtrStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _whtrStatusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BMI Classification Table (unchanged) ────────────────────────────────────
  Widget _buildBMITable(bool isDark) {
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Klasifikasi BMI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.9 : 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              _buildTableItem('Kurang', '< 18.5', const Color(0xFF3B82F6), isDark: isDark, isFirst: true),
              _buildTableItem('Normal', '18.5 - 24.9', const Color(0xFF10B981), isDark: isDark),
              _buildTableItem('Kelebihan', '25.0 - 29.9', const Color(0xFFF59E0B), isDark: isDark),
              _buildTableItem('Obesitas', '≥ 30.0', const Color(0xFFEF4444), isDark: isDark, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableItem(String label, String range, Color color,
      {required bool isDark, bool isFirst = false, bool isLast = false}) {
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final divider = isDark ? darkBorder : const Color(0x0D000000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}