import 'package:flutter/material.dart';

/// Shared colours and styles, so screens don't each hard-code their own.
class AppColors {
  static const primary = Color(0xFFFFA726);
  static const primaryLight = Color(0xFFFFE0B2);
  static const move = Colors.blueAccent;
  static const loop = Colors.green;
  static const condition = Colors.deepOrange;
  static const selected = Colors.blue;
  static const star = Colors.amber;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    // Start from the theme's own text style so button labels keep the app font.
    final buttonText = Typography.material2021().black.labelLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.bold);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: AppColors.primary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
