import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/sleep_log_result.dart';
import 'package:mobile/pages/sleep/widgets/hasil_skor_tidur_dialog.dart';
import 'package:mobile/services/sleep_service.dart';
import 'package:mobile/theme/app_colors.dart';

const _kPrimary = Color(0xFF7C3AED);

class _MoodOption {
  const _MoodOption({
    required this.value,
    required this.label,
    required this.emoji,
  });

  final String value;
  final String label;
  final String emoji;
}

const _moodOptions = [
  _MoodOption(value: 'sangat_baik', label: 'Sangat Baik', emoji: '😄'),
  _MoodOption(value: 'baik', label: 'Baik', emoji: '🙂'),
  _MoodOption(value: 'netral', label: 'Netral', emoji: '😐'),
  _MoodOption(value: 'buruk', label: 'Buruk', emoji: '😞'),
  _MoodOption(value: 'sangat_buruk', label: 'Sangat Buruk', emoji: '😡'),
];

class CatatTidurPage extends StatefulWidget {
  const CatatTidurPage({super.key});

  @override
  State<CatatTidurPage> createState() => _CatatTidurPageState();
}

class _CatatTidurPageState extends State<CatatTidurPage> {
  final _sleepService = SleepService();
  final _timeFmt = DateFormat('HH:mm');

  TimeOfDay _jamTidur = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _jamBangun = const TimeOfDay(hour: 5, minute: 50);
  int _terbangun = 0;
  int _lamaTerjaga = 0;
  String _mood = 'baik';
  bool _isLoading = false;
  bool _hasSubmitted = false;

  String _formatTime(TimeOfDay time) {
    final dt = DateTime(2026, 1, 1, time.hour, time.minute);
    return _timeFmt.format(dt);
  }

  Future<void> _pickTime({required bool isSleep}) async {
    final initial = isSleep ? _jamTidur : _jamBangun;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final border = isDark ? darkBorder : const Color(0xFFEEEEEE);

    final now = DateTime.now();
    var tempDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initial.hour,
      initial.minute,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: isDark ? darkTextSecondary : Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      isSleep ? 'Pilih Jam Tidur' : 'Pilih Jam Bangun',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final pickedTime = TimeOfDay(
                            hour: tempDateTime.hour,
                            minute: tempDateTime.minute,
                          );
                          if (isSleep) {
                            _jamTidur = pickedTime;
                          } else {
                            _jamBangun = pickedTime;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: tempDateTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempDateTime = newDateTime;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _hitungSkor() async {
    setState(() => _isLoading = true);
    try {
      final result = await _sleepService.submitSleepLog(
        SleepLogRequest(
          sleepTime: _formatTime(_jamTidur),
          wakeTime: _formatTime(_jamBangun),
          nightWakings: _terbangun,
          awakeDuration: _lamaTerjaga,
          mood: _mood,
        ),
      );
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasSubmitted = true;
      });

      try {
        await showHasilSkorTidurDialog(
          context,
          result.toDataMap(),
          showLihatRiwayatButton: true,
        );
      } catch (e, st) {
        debugPrint('CatatTidurPage showHasilSkor: $e\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data tersimpan (skor ${result.score}), tetapi gagal menampilkan hasil.',
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on SleepServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      debugPrint('CatatTidurPage._hitungSkor: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Gagal menghitung skor. Periksa koneksi ke server lalu coba lagi.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, _hasSubmitted),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Catat Tidur',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Masukkan data tidurmu hari ini',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimeField(
                    label: 'Jam Tidur',
                    value: _formatTime(_jamTidur),
                    onTap: () => _pickTime(isSleep: true),
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),
                  const SizedBox(height: 16),
                  _TimeField(
                    label: 'Jam Bangun',
                    value: _formatTime(_jamBangun),
                    onTap: () => _pickTime(isSleep: false),
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),
                  const SizedBox(height: 16),
                  _StepperField(
                    label: 'Terbangun di Malam Hari',
                    value: _terbangun,
                    suffix: 'kali',
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _terbangun = v),
                  ),
                  const SizedBox(height: 16),
                  _StepperField(
                    label: 'Lama Terjaga (Total)',
                    value: _lamaTerjaga,
                    suffix: 'menit',
                    step: 5,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _lamaTerjaga = v),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mood Setelah Bangun',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _moodOptions.map((m) {
                      final selected = _mood == m.value;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => setState(() => _mood = m.value),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _kPrimary
                                        : surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? _kPrimary
                                          : border,
                                    ),
                                  ),
                                  child: Text(
                                    m.emoji,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  m.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? _kPrimary : textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button (Floating)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _isLoading ? null : _hitungSkor,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Hitung Skor Tidur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Field ────────────────────────────────────────────────

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, color: _kPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stepper Field ─────────────────────────────────────────────

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onChanged,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    this.step = 1,
  });

  final String label;
  final int value;
  final String suffix;
  final int step;
  final ValueChanged<int> onChanged;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? darkBorder : const Color(0xFFEDE9FE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      onTap: value > 0
                          ? () => onChanged((value - step).clamp(0, 999))
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      onTap: () => onChanged(value + step),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              suffix,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: onTap != null ? _kPrimary : Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
