import 'package:flutter/material.dart';

/// Diagonal pastel gradient background
/// Atas (kanan atas): #E6D6F2 (ungu pastel)
/// Tengah: putih
/// Bawah (kiri bawah): #E6ECF7 (biru pastel)
class AppBackground extends StatelessWidget {
  final Widget? child;

  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo App
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diagonal Gradient Demo',
      theme: ThemeData(useMaterial3: true),
      home: const BackgroundScreen(),
    );
  }
}

class BackgroundScreen extends StatelessWidget {
  const BackgroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackground(),
    );
  }
}