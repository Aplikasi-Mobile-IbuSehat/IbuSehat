import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Pilih Bahasa',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F1235), letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1235), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildLanguageTile(context, 'Bahasa Indonesia', 'id', true),
              const SizedBox(height: 12),
              _buildLanguageTile(context, 'English', 'en', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String title, String code, bool isSelected) {
    return InkWell(
      onTap: () {
        // Handle language change
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.white),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1F1235),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }
}
