import 'package:flutter/material.dart';

/// Shared colours and styles, so screens don't each hard-code their own.
///
/// The main colour is a bright teal: cheerful, and not coded for boys or girls.
/// White bold text on [primary] meets the WCAG contrast level for large text.
class AppColors {
  static const primary = Color(0xFF0D9488);
  static const primaryBright = Color(0xFF14B8A6);
  static const primaryLight = Color(0xFFCCFBF1);
  static const sunshine = Color(0xFFFFC93C);
  static const sunshineLight = Color(0xFFFFF4D1);
  static const sky = Color(0xFF2F80ED);
  static const skyLight = Color(0xFFE3EEFF);
  static const violet = Color(0xFF8B5CF6);
  static const violetLight = Color(0xFFEFE8FF);
  static const coral = Color(0xFFFF6B6B);
  static const ink = Color(0xFF1B2A3A);
  static const inkSoft = Color(0xFF52606D);

  static const move = sky;
  static const loop = Color(0xFF16A34A);
  static const condition = violet;
  static const selected = Color(0xFFF59E0B);
  static const star = Color(0xFFFFC107);
  static const danger = Color(0xFFE11D48);
}

/// A soft, bright background used behind most screens.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6FFFA), Color(0xFFF0F7FF), Color(0xFFFFF8E6)],
  );

  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: const BoxDecoration(gradient: gradient), child: child);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.sunshine,
      tertiary: AppColors.violet,
      surface: Colors.white,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    // Start from the theme's own text style so button labels keep the app font.
    final buttonText = Typography.material2021().black.labelLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.bold);
    final base = ThemeData(colorScheme: scheme);
    final titleText =
        base.textTheme.titleLarge!.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4FBFA),
      textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        // Built from the theme's text style, so the title keeps the app font.
        titleTextStyle: titleText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          textStyle: buttonText,
          shape: buttonShape,
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: base.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: AppColors.primary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primaryLight : Colors.white,
          ),
        ),
      ),
    );
  }
}
