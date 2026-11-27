import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static TextStyle _base(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle labelLg([Color color = AppColors.onSurface]) =>
      _base(14, 20, FontWeight.w600, color);
  static TextStyle labelSm([Color color = AppColors.onSurface]) =>
      _base(11, 14, FontWeight.w600, color);
  static TextStyle headlineXlMobile([Color color = AppColors.onSurface]) =>
      _base(28, 36, FontWeight.w700, color, letterSpacing: -0.7);
  static TextStyle bodyMd([Color color = AppColors.onSurface]) =>
      _base(14, 20, FontWeight.w400, color);
  static TextStyle bodySm([Color color = AppColors.onSurface]) =>
      _base(12, 16, FontWeight.w400, color);
}

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 6,
      spreadRadius: -1,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 4,
      spreadRadius: -2,
      offset: const Offset(0, 2),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    );
  }
}