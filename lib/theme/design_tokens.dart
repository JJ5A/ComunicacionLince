import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color brandPrimary = Color(0xFF005B8F);
  static const Color brandSecondary = Color(0xFF0FC5A8);
  static const Color brandTertiary = Color(0xFF6F4BCE);

  static const Color surface = Color(0xFFF7F8FB);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1D2B3A);
  static const Color textMuted = Color(0xFF6E7C8D);

  static const Gradient heroGradient = LinearGradient(
    colors: <Color>[Color(0xFF015C92), Color(0xFF0BB7A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient messageGradient = LinearGradient(
    colors: <Color>[Color(0xFF0470B8), Color(0xFF0FC5A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient shellGradient = LinearGradient(
    colors: <Color>[Color(0xFFF8FAFF), Color(0xFFEFF4FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

class AppShadows {
  const AppShadows._();

  static final List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppDecorations {
  const AppDecorations._();

  static const BoxDecoration heroBackground = BoxDecoration(gradient: AppColors.heroGradient);
  static const BoxDecoration surfaceBackground = BoxDecoration(gradient: AppColors.shellGradient);
}
