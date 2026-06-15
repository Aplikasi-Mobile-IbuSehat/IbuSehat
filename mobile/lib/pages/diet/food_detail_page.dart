import 'package:flutter/material.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/theme/app_colors.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;

  const FoodDetailPage({super.key, required this.food});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int _servingSize = 1;
  late double _weight;
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weight = widget.food.weight;
    _weightController.text = widget.food.weight.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double get totalWeight => _weight * _servingSize;
  double get totalKcal => widget.food.weight > 0 ? (widget.food.kcal / widget.food.weight) * totalWeight : 0;
  double get totalProtein => widget.food.weight > 0 ? (widget.food.protein / widget.food.weight) * totalWeight : 0;
  double get totalCarbs => widget.food.weight > 0 ? (widget.food.carbs / widget.food.weight) * totalWeight : 0;
  double get totalFat => widget.food.weight > 0 ? (widget.food.fat / widget.food.weight) * totalWeight : 0;

  static const Map<String, String> _categoryEmoji = {
    'Buah-buahan': '🍎',
    'Sayuran Segar': '🥦',
    'Kacang & Biji': '🥜',
    'Susu Segar': '🥛',
    'Olahan Sederhana': '🍳',
    'Lainnya': '🌿',
  };

  String _emojiForFood(Food food) =>
      food.category != null ? (_categoryEmoji[food.category] ?? '🍽️') : '🍽️';

  void _incrementServing() => setState(() => _servingSize++);
  void _decrementServing() {
    if (_servingSize > 1) setState(() => _servingSize--);
  }

  void _saveFood() {
    final scaled = Food(
      id: widget.food.id,
      name: widget.food.name,
      weight: totalWeight,
      kcal: totalKcal,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      category: widget.food.category,
      icon: widget.food.icon,
      color: widget.food.color,
    );
    Navigator.pop(context, scaled);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final background = isDark ? darkBackground : const Color(0xFFF2F2F7);
    final surface = isDark ? darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Nutrisi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveFood,
            child: const Text(
              'Tambah',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ─────────────────────────────────────────────────────
            _buildHeroCard(isDark, surface, textPrimary, textSecondary),
            const SizedBox(height: 12),

            // ── Servings Control ──────────────────────────────────────────────
            _buildServingsCard(isDark, surface, textPrimary, textSecondary),
            const SizedBox(height: 12),

            // ── Nutrition Summary ─────────────────────────────────────────────
            _buildNutritionCard(isDark, surface, textPrimary, textSecondary),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark, Color surface, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? darkBackground : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _emojiForFood(widget.food),
                style: const TextStyle(fontSize: 38),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.food.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.food.kcal.toStringAsFixed(0)} kkal / ${widget.food.weight.toStringAsFixed(0)} g',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (widget.food.category != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? darkBackground : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.food.category!,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServingsCard(bool isDark, Color surface, Color textPrimary, Color textSecondary) {
    final border = isDark ? darkBorder : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Serving stepper row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Jumlah Sajian',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                _buildStepper(isDark, textPrimary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, thickness: 0.5, color: border),
          ),
          // Weight per serving row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Berat per Sajian',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _weight = double.tryParse(val) ?? widget.food.weight;
                      });
                    },
                    decoration: InputDecoration(
                      suffix: Text(
                        ' g',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
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

  Widget _buildStepper(bool isDark, Color textPrimary) {
    return Row(
      children: [
        _buildStepButton(Icons.remove, _decrementServing, isDark, textPrimary),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$_servingSize',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        _buildStepButton(Icons.add, _incrementServing, isDark, textPrimary),
      ],
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap, bool isDark, Color textPrimary) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? darkBackground : const Color(0xFFE5E5EA),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: textPrimary),
      ),
    );
  }

  Widget _buildNutritionCard(bool isDark, Color surface, Color textPrimary, Color textSecondary) {
    final border = isDark ? darkBorder : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nilai Gizi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${totalWeight.toStringAsFixed(0)} g total',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _buildNutritionRow('Kalori', totalKcal, 'kkal', textPrimary, textSecondary, border, isFirst: true),
          _buildNutritionRow('Protein', totalProtein, 'g', textPrimary, textSecondary, border),
          _buildNutritionRow('Karbohidrat', totalCarbs, 'g', textPrimary, textSecondary, border),
          _buildNutritionRow('Lemak', totalFat, 'g', textPrimary, textSecondary, border, isLast: true),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    double value,
    String unit,
    Color textPrimary,
    Color textSecondary,
    Color border, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(height: 1, thickness: 0.5, color: border),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textPrimary,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
