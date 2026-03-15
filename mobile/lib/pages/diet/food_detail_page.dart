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
  double get totalKcal => (widget.food.kcal / widget.food.weight) * totalWeight;
  double get totalProtein => (widget.food.protein / widget.food.weight) * totalWeight;
  double get totalCarbs => (widget.food.carbs / widget.food.weight) * totalWeight;
  double get totalFat => (widget.food.fat / widget.food.weight) * totalWeight;
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
        title: const Text(
          'Detail Makanan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F1235),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFB084F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🍜', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.food.kcal.toStringAsFixed(0)} kcal / ${widget.food.weight.toStringAsFixed(0)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Controls & Nutrition ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Sajian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1235),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EBFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _decrementServing,
                                  icon: const Icon(Icons.remove_rounded),
                                  color: _servingSize > 1
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.grey,
                                  iconSize: 22,
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '$_servingSize',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1235),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _incrementServing,
                                  icon: const Icon(Icons.add_rounded),
                                  color: const Color(0xFF8B5CF6),
                                  iconSize: 22,
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Sajian',
                                style: TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Berat (Gram)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1235),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: widget.food.weight.toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          setState(() {
                            _weight = double.tryParse(val) ?? widget.food.weight;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFF8B5CF6), width: 2),
                          ),
                          suffixText: 'g',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // ── Nutrition Card ──────────────────────────────────
                      Container(
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Nilai Gizi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F1235),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildNutritionRow(
                                'Kalori',
                                '${totalKcal.toStringAsFixed(0)} kcal',
                                isMain: true),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildNutritionRow(
                                'Protein', '${totalProtein.toStringAsFixed(1)} g'),
                            const SizedBox(height: 14),
                            _buildNutritionRow(
                                'Karbohidrat', '${totalCarbs.toStringAsFixed(1)} g'),
                            const SizedBox(height: 14),
                            _buildNutritionRow(
                                'Lemak', '${totalFat.toStringAsFixed(1)} g'),
                            const SizedBox(height: 14),
                            _buildNutritionRow(
                                'Serat', '${totalFiber.toStringAsFixed(1)} g'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMain ? 18 : 16,
            fontWeight: isMain ? FontWeight.w600 : FontWeight.w500,
            color: isMain ? const Color(0xFF1F1235) : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 20 : 16,
            fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
            color: isMain ? const Color(0xFF7C3AED) : const Color(0xFF1F1235),
          ),
        ),
      ],
    );
  }
}
