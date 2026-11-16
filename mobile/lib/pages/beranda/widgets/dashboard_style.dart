import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

/// Token visual khusus dashboard (Beranda).
///
/// Prinsipnya: kartu tenang (putih, garis tipis, tanpa bayangan tebal), dan
/// warna merek ungu–pink hanya dipakai di satu tempat, yaitu rantai streak.
class DashboardStyle {
  DashboardStyle._(this.isDark);

  factory DashboardStyle.of(BuildContext context) =>
      DashboardStyle._(Theme.of(context).brightness == Brightness.dark);

  final bool isDark;

  // Aksen merek (sama dengan cardGradient aplikasi).
  static const Color iris = Color(0xFF7C3AED);
  static const LinearGradient chainGradient = cardGradient;

  // Warna metrik: satu keluarga, saturasi seragam.
  static const Color workout = Color(0xFF6D4AE0);
  static const Color water = Color(0xFF2C7BE5);
  static const Color nutrition = Color(0xFF239A63);
  static const Color sleep = Color(0xFFC0407A);

  static const double radius = 22;

  Color get card => isDark ? darkSurface : lightSurface;
  Color get hairline => isDark ? const Color(0xFF2E2A36) : const Color(0xFFEAE6F0);
  Color get ink => isDark ? darkTextPrimary : const Color(0xFF1C1626);
  Color get muted => isDark ? darkTextSecondary : const Color(0xFF7A7386);
  Color get faint => isDark ? const Color(0xFF55505E) : const Color(0xFFC9C3D3);
  Color get track => isDark ? const Color(0xFF2E2A36) : const Color(0xFFF0EDF4);

  BoxDecoration cardDecoration() => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hairline),
      );

  /// Teks kecil penanda bagian (huruf kapital, renggang).
  TextStyle get eyebrow => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: muted,
      );

  /// Angka besar dengan digit selebar seragam supaya tidak "melompat".
  TextStyle figure(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -size * 0.04,
        color: ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
