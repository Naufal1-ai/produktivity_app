import 'package:flutter/material.dart';
import 'package:productivity/main.dart' show themeColorNotifier, themeNotifier;

class AppColors {
  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static Color get brand => themeColorNotifier.value;
  static Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // Background
  // Warna bg kini diselaraskan dengan gradient Kanban agar semua tab terlihat konsisten
  static Color get bg =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  static Color get bgCard => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get bgCardAlt =>
      isDark ? const Color(0xFF1A2332) : const Color(0xFFE8EDF5);

  // Brand accent. Keep the old names so existing UI code follows the selected theme color.
  static Color get blueDark => _shiftLightness(brand, -0.34);
  static Color get blueMid => _shiftLightness(brand, -0.08);
  static Color get blueBorder => _shiftLightness(brand, 0.02);
  static Color get blueAccent => brand;
  static Color get blueText => _shiftLightness(brand, 0.24);
  static Color get blueMuted => _shiftLightness(brand, 0.14);
  static Color get primaryWeb => brand;

  // Text
  static Color get textPrimary =>
      isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA6ABB4) : const Color(0xFF334155);
  static Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF64748B);
  static Color get textDim =>
      isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8);

  // Semantic
  static const income = Color(0xFF10B981); // Success Green
  static const greenSuccess = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444); // Danger Red
  static const purple = Color(0xFF8B5CF6); // Accent Purple
  static Color get border =>
      isDark ? const Color(0xFF1E2130) : const Color(0xFFE2E8F0);
  static Color get borderAccent =>
      isDark ? const Color(0xFF2A2D3E) : const Color(0xFFCBD5E1);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'DMSans',
      colorScheme: ColorScheme.dark(
        primary: AppColors.blueAccent,
        secondary: AppColors.blueMid,
        surface: AppColors.bgCard,
        error: AppColors.expense,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueMid,
          foregroundColor: AppColors.blueText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.blueBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSans',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blueBorder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        labelSmall: TextStyle(
            color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8),
      ),
      dividerColor: AppColors.border,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.blueAccent,
        unselectedItemColor: AppColors.textDim,
        elevation: 0,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'DMSans',
      colorScheme: ColorScheme.light(
        primary: AppColors.blueAccent,
        secondary: AppColors.blueMid,
        surface: Colors.white,
        error: AppColors.expense,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueMid,
          foregroundColor: AppColors.blueText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.blueBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSans',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blueBorder, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 36,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        headlineMedium: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        titleLarge: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 15),
        bodyMedium: TextStyle(color: Color(0xFF475569), fontSize: 13),
        labelSmall: TextStyle(
            color: Color(0xFF64748B), fontSize: 11, letterSpacing: 0.8),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.blueAccent,
        unselectedItemColor: const Color(0xFF64748B),
        elevation: 0,
      ),
    );
  }
}
