import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const seed = AppColors.brandPrimary;
    final colorScheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      secondary: AppColors.brandSecondary,
      surface: AppColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Segoe UI',
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        shadowColor: Colors.black12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: const BorderSide(color: AppColors.brandPrimary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
      dividerColor: Colors.black12,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
        selectedColor: AppColors.brandPrimary,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
    );
  }
}
