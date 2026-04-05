import 'package:flutter/material.dart';
import 'package:mobile/widgets/app_background.dart';
import 'dart:math' as math;

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  State<BMICalculatorPage> createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final _weightController = TextEditingController(text: '60');
  final _heightController = TextEditingController(text: '165');
  double? _bmi;
  String _status = '';
  Color _statusColor = Colors.grey;

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight != null && height != null && height > 0) {
      setState(() {
        _bmi = weight / math.pow(height / 100, 2);
        _updateStatus(_bmi!);
      });
    }
  }

  void _updateStatus(double bmi) {
    if (bmi < 18.5) {
      _status = 'Kekurangan Berat Badan';
      _statusColor = const Color(0xFF3B82F6); // Blue
    } else if (bmi < 25) {
      _status = 'Normal (Ideal)';
      _statusColor = const Color(0xFF10B981); // Green
    } else if (bmi < 30) {
      _status = 'Kelebihan Berat Badan';
      _statusColor = const Color(0xFFF59E0B); // Orange
    } else {
      _status = 'Obesitas';
      _statusColor = const Color(0xFFEF4444); // Red
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateBMI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Kalkulator BMI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1235), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(),
                const SizedBox(height: 32),
                if (_bmi != null) _buildResultSection(),
                const SizedBox(height: 32),
                _buildBMITable(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          _buildInputField(
            label: 'Berat Badan',
            controller: _weightController,
            unit: 'Kg',
            onChanged: (v) => _calculateBMI(),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            label: 'Tinggi Badan',
            controller: _heightController,
            unit: 'Cm',
            onChanged: (v) => _calculateBMI(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1235),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              suffixText: unit,
              suffixStyle: TextStyle(
                color: const Color(0xFF1F1235).withOpacity(0.4),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor.withOpacity(0.8), _statusColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.3),
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
            _bmi!.toStringAsFixed(1),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _status,
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

  Widget _buildBMITable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Klasifikasi BMI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            children: [
              _buildTableItem('Kurang', '< 18.5', const Color(0xFF3B82F6), isFirst: true),
              _buildTableItem('Normal', '18.5 - 24.9', const Color(0xFF10B981)),
              _buildTableItem('Kelebihan', '25.0 - 29.9', const Color(0xFFF59E0B)),
              _buildTableItem('Obesitas', '≥ 30.0', const Color(0xFFEF4444), isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableItem(String label, String range, Color color, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.black.withOpacity(0.05)),
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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1235),
                ),
              ),
            ],
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1235).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
