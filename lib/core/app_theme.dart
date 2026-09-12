import 'package:flutter/material.dart';

/// Paleta y tema de la aplicación.
///
/// Evita APIs que cambiaron de tipo entre versiones de Flutter (`cardTheme`,
/// `Color.withValues`) para compilar igual en 3.19 y en versiones recientes.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF14385C);
  static const Color primaryLight = Color(0xFF2C5F92);
  static const Color accent = Color(0xFFD98032);
  static const Color surface = Color(0xFFF4F6F8);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFDFE4EA);
  static const Color textStrong = Color(0xFF16202B);
  static const Color textSoft = Color(0xFF56626F);

  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB26A00);
  static const Color success = Color(0xFF1B7F4B);
  static const Color info = Color(0xFF1F5F8B);

  /// Color por fase del proyecto.
  static const Color initiation = Color(0xFF6A4C93);
  static const Color planning = Color(0xFF1F5F8B);
  static const Color execution = Color(0xFF1B7F4B);
  static const Color risk = Color(0xFFB26A00);
  static const Color closure = Color(0xFF14385C);
}

class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textStrong,
        ),
        bodyMedium: TextStyle(color: AppColors.textStrong, height: 1.35),
        bodySmall: TextStyle(color: AppColors.textSoft, height: 1.3),
      ),
    );
  }
}
