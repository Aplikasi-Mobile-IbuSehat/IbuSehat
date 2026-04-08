import 'package:flutter/material.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/widgets/app_background.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;

  const FoodDetailPage({super.key, required this.food});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int _servingSize = 1;
  late double _weight;

  @override
  void initState() {
    super.initState();
    _weight = widget.food.weight;
  }

  double get totalWeight => _weight * _servingSize;
  double get totalKcal => widget.food.weight > 0 ? (widget.food.kcal / widget.food.weight) * totalWeight : 0;
  double get totalProtein => widget.food.weight > 0 ? (widget.food.protein / widget.food.weight) * totalWeight : 0;
  double get totalCarbs => widget.food.weight > 0 ? (widget.food.carbs / widget.food.weight) * totalWeight : 0;
  double get totalFat => widget.food.weight > 0 ? (widget.food.fat / widget.food.weight) * totalWeight : 0;
  double get totalFiber => totalCarbs * 0.15;

  void _incrementServing() => setState(() => _servingSize++);

  void _decrementServing() {
    if (_servingSize > 1) setState(() => _servingSize--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1235), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Nutrisi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Section ─────────────────────────────────────────────
                _buildHeroCard(),
                const SizedBox(height: 24),

                // ── Servings Control ─────────────────────────────────────────
                _buildServingsControl(),
                const SizedBox(height: 24),

                // ── Nutrition Info Card ──────────────────────────────────────
                _buildNutritionCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Text('🍜', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          Text(
            widget.food.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F1235),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.food.kcal.toStringAsFixed(0)} kcal / ${widget.food.weight.toStringAsFixed(0)}g',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingsControl() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sesuaikan Porsi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1235),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAdjustButton(Icons.remove_rounded, _decrementServing),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_servingSize',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F1235),
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'Sajian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAdjustButton(Icons.add_rounded, _incrementServing),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          const Text(
            'Berat per Sajian',
            style: TextStyle(
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
            child: TextFormField(
              initialValue: widget.food.weight.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  _weight = double.tryParse(val) ?? widget.food.weight;
                });
              },
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1235),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                suffixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'gram',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF8B5CF6), size: 28),
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1235),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F1235).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nilai Gizi Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalWeight.toStringAsFixed(0)}g',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNutritionItem('Kalori', totalKcal, 'kkal', Colors.orangeAccent),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniNutrition('Protein', totalProtein, 'g', Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniNutrition('Karbo', totalCarbs, 'g', Colors.greenAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniNutrition('Lemak', totalFat, 'g', Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNutrition(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
