import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

class AppThemeController extends ChangeNotifier {
  static const _prefKey = 'app_theme_preference';

  AppThemePreference _preference = AppThemePreference.system;
  AppThemePreference get preference => _preference;

  ThemeMode get themeMode {
    switch (_preference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  bool get isSystemMode => _preference == AppThemePreference.system;
  bool get isDarkManual => _preference == AppThemePreference.dark;
  bool get isLightManual => _preference == AppThemePreference.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    _preference = AppThemePreference.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppThemePreference.system,
    );
    notifyListeners();
  }

  Future<void> setSystemMode(bool enabled) async {
    _preference = enabled
        ? AppThemePreference.system
        : (_preference == AppThemePreference.system
            ? AppThemePreference.light
            : _preference);
    await _persist();
    notifyListeners();
  }

  Future<void> setManualDark(bool isDark) async {
    _preference = isDark ? AppThemePreference.dark : AppThemePreference.light;
    await _persist();
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _preference.name);
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA855F7),
        brightness: Brightness.light,
        surface: lightSurface,
      ),
    );

    return base.copyWith(
      cardColor: lightSurface,
      dialogTheme: const DialogThemeData(backgroundColor: lightSurface),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: TextStyle(color: lightTextPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: lightSurface,
        filled: true,
        hintStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: lightIcon),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA855F7),
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
    );

    return base.copyWith(
      cardColor: darkSurface,
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: TextStyle(color: darkTextPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: darkSurface,
        filled: true,
        hintStyle: const TextStyle(color: darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkTextPrimary,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: darkIcon),
    );
  }
}

final AppThemeController appThemeController = AppThemeController();
