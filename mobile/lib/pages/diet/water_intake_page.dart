import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/widgets/app_background.dart';

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
  late int _currentIntake;

  @override
  void initState() {
    super.initState();
    _currentIntake = widget.currentIntake;
  }

  @override
  void didUpdateWidget(WaterIntakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIntake != widget.currentIntake) {
      setState(() {
        _currentIntake = widget.currentIntake;
      });
    }
  }

  void _addWater(int amount) {
    setState(() {
      _currentIntake += amount;
    });
    widget.onAddWater(amount);
  }

  void _showCustomInputDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Jumlah Khusus',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1F1235)),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Masukkan jumlah',
              suffixText: 'ml',
              suffixStyle: const TextStyle(
                  color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF8B5CF6), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F3FF),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                final amount = int.tryParse(controller.text) ?? 0;
                if (amount > 0) {
                  _addWater(amount);
                }
                Navigator.pop(context);
              },
              child: const Text('Tambah',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  double get _progress =>
      (_currentIntake / widget.goalIntake).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Catat asupan airmu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Color(0xFF1F1235)),
          ),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          size: 40, color: Colors.white70),
                      const SizedBox(height: 12),
                      Text(
                        '$_currentIntake ml',
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
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0 ml',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${(_progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${widget.goalIntake} ml',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
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

                // Sasaran label
                Text(
                  'Sasaran Harian: ${widget.goalIntake} ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Section Title ─────────────────────────────────────────
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Ukuran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Container Option Row ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/glass.svg',
                        width: 30,
                      ),
                      label: '250 ml',
                      amount: 250,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/medium_bottle.svg',
                        height: 60,
                      ),
                      label: '500 ml',
                      amount: 500,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/gallon_water.svg',
                        height: 70,
                      ),
                      label: '1000 ml',
                      amount: 1000,
                    ),
                    _buildOption(
                      iconWidget: SvgPicture.asset(
                        'assets/icons/custom_glass_bottle.svg',
                        height: 70,
                      ),
                      label: 'Jumlah\nKhusus',
                      amount: null,
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // ── Simpan Button ─────────────────────────────────────────
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
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
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF8B5CF6).withOpacity(0.15),
          highlightColor: const Color(0xFF8B5CF6).withOpacity(0.05),
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
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
                // Icon area
                SizedBox(
                  height: 80,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: iconWidget,
                  ),
                ),
                const SizedBox(height: 12),
                // Label area
                SizedBox(
                  height: 36,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
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
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
