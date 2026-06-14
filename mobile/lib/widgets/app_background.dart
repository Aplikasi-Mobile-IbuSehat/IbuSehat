import 'package:flutter/material.dart';

/// Background layar utama aplikasi.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFC),
      ),
      child: child,
    );
  }
}
