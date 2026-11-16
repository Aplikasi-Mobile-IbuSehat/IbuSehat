import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/pages/settings/edit_health_data_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';

/// Gerbang fitur yang memakai data kesehatan (Chatbot AI, program latihan).
///
/// Data lengkap → langsung lanjut. Belum lengkap → popup penjelasan dengan
/// tombol ke halaman Data Kesehatan; simpan valid → lanjut ke fitur,
/// batal → tetap tertutup.
class HealthGate {
  HealthGate._();

  /// Fitur yang terbuka setelah data kesehatan diisi (ditampilkan di popup).
  static const List<({IconData icon, String title, String subtitle})>
      _unlockedFeatures = [
    (
      icon: Icons.chat_bubble_outline_rounded,
      title: 'IbuSehat AI',
      subtitle: 'Tanya jawab seputar nutrisi dan pemulihan',
    ),
    (
      icon: Icons.fitness_center_rounded,
      title: 'Program Latihan',
      subtitle: 'Latihan yang disesuaikan dengan kondisimu',
    ),
  ];

  /// [showIntro] false: lewati popup dan langsung buka Data Kesehatan
  /// (dipakai saat layar pemanggil sudah menjelaskan sendiri).
  static Future<bool> ensure(
    BuildContext context, {
    bool showIntro = true,
  }) async {
    final auth = AuthService.instance;
    if (auth.healthDataCompleteSync) return true;

    // Cache lokal bisa basi (mis. data diisi dari perangkat lain).
    try {
      await auth.syncUserFromApi().timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (auth.healthDataCompleteSync) return true;
    if (!context.mounted) return false;

    if (showIntro) {
      final proceed = await _showIntroDialog(context);
      if (proceed != true || !context.mounted) return false;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditHealthDataPage()),
    );
    return saved == true && auth.healthDataCompleteSync;
  }

  /// Buka [builder] hanya jika data kesehatan sudah/baru saja dilengkapi.
  static Future<void> open(BuildContext context, WidgetBuilder builder) async {
    if (!await ensure(context)) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  static Future<bool?> _showIntroDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final surface = isDark ? darkSurface : lightSurface;
        final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
        final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

        return Dialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Isi data kesehatan dulu, yuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fitur ini memakai data kesehatan kamu. Setelah diisi, '
                    'kamu bisa mengakses:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final feature in _unlockedFeatures)
                    _FeatureRow(
                      icon: feature.icon,
                      title: feature.title,
                      subtitle: feature.subtitle,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Isi Data Kesehatan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Nanti saja',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF4C1D95).withValues(alpha: 0.25)
              : const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
