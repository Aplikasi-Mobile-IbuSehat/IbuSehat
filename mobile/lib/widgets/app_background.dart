import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

/// Background layar utama aplikasi.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? darkBackground : const Color(0xFFFAFAFC),
      ),
      child: child,
    );
  }
}

