import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final tileBg = isDark ? darkSurface : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark ? darkBorder : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Pilih Bahasa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _buildLanguageTile(
              context,
              'Bahasa Indonesia',
              'id',
              true,
              textPrimary: textPrimary,
              tileBg: tileBg,
              borderColor: borderColor,
            ),
            const SizedBox(height: 12),
            _buildLanguageTile(
              context,
              'English',
              'en',
              false,
              textPrimary: textPrimary,
              tileBg: tileBg,
              borderColor: borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String title,
    String code,
    bool isSelected, {
    required Color textPrimary,
    required Color tileBg,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: () {
        // Handle language change
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : borderColor),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textPrimary,
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
