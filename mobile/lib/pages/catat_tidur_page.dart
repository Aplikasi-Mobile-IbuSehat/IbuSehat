import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/sleep_log_result.dart';
import 'package:mobile/pages/sleep/widgets/hasil_skor_tidur_dialog.dart';
import 'package:mobile/services/sleep_service.dart';

const _kPrimary = Color(0xFF7C3AED);
const _kDark = Color(0xFF1F1235);
const _kGrey = Color(0xFF9CA3AF);
const _kBg = Color(0xFFF8F9FB);
const _kChipBg = Color(0xFFEDE9FE);

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
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isSleep) {
        _jamTidur = picked;
      } else {
        _jamBangun = picked;
      }
    });
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
              'Data tersimpan (skor ${result.score}), tetapi gagal '
              'menampilkan hasil.',
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

  Widget _buildFormAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pop(context, _hasSubmitted),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                  color: _kDark,
                ),
                const Expanded(
                  child: Text(
                    'Catat Tidur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Masukkan data tidurmu hari ini',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildFormAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimeField(
                      label: 'Jam Tidur',
                      value: _formatTime(_jamTidur),
                      onTap: () => _pickTime(isSleep: true),
                    ),
                    const SizedBox(height: 20),
                    _TimeField(
                      label: 'Jam Bangun',
                      value: _formatTime(_jamBangun),
                      onTap: () => _pickTime(isSleep: false),
                    ),
                    const SizedBox(height: 20),
                    _StepperField(
                      label: 'Terbangun di Malam Hari',
                      value: _terbangun,
                      suffix: 'kali',
                      onChanged: (v) => setState(() => _terbangun = v),
                    ),
                    const SizedBox(height: 20),
                    _StepperField(
                      label: 'Lama Terjaga (Total)',
                      value: _lamaTerjaga,
                      suffix: 'menit',
                      step: 5,
                      onChanged: (v) => setState(() => _lamaTerjaga = v),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Mood Setelah Bangun',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _moodOptions.map((m) {
                        final selected = _mood == m.value;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () => setState(() => _mood = m.value),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? _kPrimary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? _kPrimary
                                            : Colors.grey.shade200,
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
                                      color:
                                          selected ? _kPrimary : _kGrey,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _hitungSkor,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor:
                        _kPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, color: _kPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final String suffix;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _kChipBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: value > 0
                          ? () => onChanged((value - step).clamp(0, 999))
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                          ),
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: () => onChanged(value + step),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onTap != null ? _kPrimary : _kGrey.withValues(alpha: 0.4),
            size: 20,
          ),
        ),
      ),
    );
  }
}
