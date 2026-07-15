import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const gold = Color(0xFFE8C547);
  static const goldDark = Color(0xFFD4AF37);
  static const deepGreen = Color(0xFF005A36);
  static const deepGreenLight = Color(0xFF00884F);
  static const richRed = Color(0xFFCE1126);
  static const cream = Color(0xFFF7F4EF);
  static const charcoal = Color(0xFF1A1A1A);
  static const softGreen = Color(0xFFE6F4EC);
  static const textMuted = Color(0xFF64748B);
  static const cardShadow = Color(0x1A005A36);
}

class AppDecor {
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static BorderRadius get radiusLg => BorderRadius.circular(24);
  static BorderRadius get radiusMd => BorderRadius.circular(18);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepGreen,
        primary: AppColors.deepGreen,
        secondary: AppColors.gold,
        surface: AppColors.cream,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.charcoal,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.charcoal,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusMd),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepGreen,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: AppColors.deepGreen.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: AppDecor.radiusMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDecor.radiusMd,
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDecor.radiusMd,
          borderSide: const BorderSide(color: AppColors.deepGreen, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.softGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.deepGreen : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.deepGreen : AppColors.textMuted,
            size: 24,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
