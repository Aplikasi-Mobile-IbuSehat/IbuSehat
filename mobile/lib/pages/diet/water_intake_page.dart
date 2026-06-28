import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/services/water_intake_service.dart';
import 'package:mobile/models/water_intake.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/progress_provider.dart';

class WaterIntakePage extends StatefulWidget {
  final int currentIntake;
  final int goalIntake;
  final ValueChanged<int> onAddWater;

  const WaterIntakePage({
    super.key,
    required this.currentIntake,
    required this.goalIntake,
    required this.onAddWater,
  });

  @override
  State<WaterIntakePage> createState() => _WaterIntakePageState();
}

class _WaterIntakePageState extends State<WaterIntakePage> {
  final _service = WaterIntakeService.instance;

  late int _currentIntake;

  int _pendingDelta = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIntake = widget.currentIntake;
  }

  int get _displayIntake => (_currentIntake + _pendingDelta).clamp(0, 99999);
  double get _progress => (_displayIntake / widget.goalIntake).clamp(0.0, 1.0);
  bool get _hasPendingChanges => _pendingDelta != 0;

  void _addWater(int amount) {
    setState(() => _pendingDelta += amount);
    widget.onAddWater(amount);
  }

  Future<void> _save() async {
    if (!_hasPendingChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      WaterIntakeModel updated;

      if (_pendingDelta > 0) {
        updated = await _service.addWaterIntake(_pendingDelta);
      } else {
        updated = await _service.reduceWaterIntake(_pendingDelta.abs());
      }

      if (mounted) {
        setState(() {
          _currentIntake = updated.waterIntake;
          _pendingDelta = 0;
        });
        context.read<ProgressProvider>().fetchSummary(forceRefresh: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        widget.onAddWater(-_pendingDelta);
        setState(() => _pendingDelta = 0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCustomInputDialog() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? darkSurface : lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Jumlah Khusus',
          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah',
            suffixText: 'ml',
            suffixStyle: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            filled: true,
            fillColor: isDark ? darkBackground : lightBackground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              if (amount > 0) _addWater(amount);
            },
            child: const Text(
              'Tambah',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showReduceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Koreksi Asupan Air',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kurangi jumlah yang sudah tercatat',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [250, 500, 1000].map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: amount != 1000 ? 12 : 0),
                      child: _buildReduceChip(
                        amount: amount,
                        border: border,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _pendingDelta -= amount);
                          widget.onAddWater(-amount);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReduceChip({
    required int amount,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
        ),
        alignment: Alignment.center,
        child: Text(
          '−$amount ml',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Catatan Asupan Air',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: _isSaving ? textSecondary : const Color(0xFF8B5CF6),
              size: 24,
            ),
            tooltip: 'Koreksi asupan',
            onPressed: _isSaving ? null : _showReduceSheet,
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              children: [
                // ── Volume Total Box ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 40,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 12),
                      if (_hasPendingChanges)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _pendingDelta > 0
                                ? '+$_pendingDelta ml belum disimpan'
                                : '$_pendingDelta ml belum disimpan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        '$_displayIntake ml',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0 ml',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(_progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${widget.goalIntake} ml',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sasaran Harian: ${widget.goalIntake} ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Ukuran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/glass.svg',
                        width: 30,
                        colorFilter: ColorFilter.mode(
                          isDark ? darkTextPrimary : lightTextPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: '250 ml',
                      amount: 250,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/medium_bottle.svg',
                        height: 60,
                        colorFilter: ColorFilter.mode(
                          isDark ? darkTextPrimary : lightTextPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: '500 ml',
                      amount: 500,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/gallon_water.svg',
                        height: 70,
                        colorFilter: ColorFilter.mode(
                          isDark ? darkTextPrimary : lightTextPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: '1000 ml',
                      amount: 1000,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/custom_glass_bottle.svg',
                        height: 70,
                        colorFilter: ColorFilter.mode(
                          isDark ? darkTextPrimary : lightTextPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Jumlah\nKhusus',
                      amount: null,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // ── Tombol Simpan ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
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
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required Widget iconWidget,
    required String label,
    required int? amount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          highlightColor: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: _isSaving
              ? null
              : () {
                  if (amount == null) {
                    _showCustomInputDialog();
                  } else {
                    _addWater(amount);
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 80,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: iconWidget,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
