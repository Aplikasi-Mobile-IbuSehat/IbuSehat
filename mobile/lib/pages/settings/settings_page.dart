import 'package:flutter/material.dart';
import 'package:mobile/widgets/app_background.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F1235), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: const SafeArea(
          child: Center(
            child: Text('Settings Page Placeholder', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}
