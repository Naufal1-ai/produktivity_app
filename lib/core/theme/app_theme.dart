import 'package:flutter/material.dart';
import 'package:productivity/main.dart'
    show appStyleNotifier, themeColorNotifier, themeNotifier;
import 'package:productivity/core/theme/app_style_theme.dart';

class AppColors {
  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static bool get isSaweriaClassic =>
      appStyleNotifier.value == AppStyleTheme.saweriaClassic;
  static Color get brand => themeColorNotifier.value;
  static const retroInk = Color(0xFF232120);
  static const retroCream = Color(0xFFF3E9DD);
  static const retroPaper = Color(0xFFFFFDF8);
  static const retroTeal = Color(0xFF5CCAB4);
  static const retroBlue = Color(0xFF88BBFF);
  static const retroPink = Color(0xFFFF8B9C);
  static const retroYellow = Color(0xFFFFB338);
  static Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  // Background
  // Warna bg kini diselaraskan dengan gradient Kanban agar semua tab terlihat konsisten
  static Color get bg {
    if (isSaweriaClassic) {
      return retroCream;
    }
    return isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  }

  static Color get bgCard {
    if (isSaweriaClassic) {
      return retroPaper;
    }
    return isDark ? const Color(0xFF1E293B) : Colors.white;
  }

  static Color get bgCardAlt {
    if (isSaweriaClassic) {
      return const Color(0xFFFFE2B5);
    }
    return isDark ? const Color(0xFF1A2332) : const Color(0xFFE8EDF5);
  }

  // Brand accent. Keep the old names so existing UI code follows the selected theme color.
  static Color get _activeBrand => isSaweriaClassic ? retroTeal : brand;
  static Color get blueDark => isSaweriaClassic
      ? const Color(0xFF27837E)
      : _shiftLightness(_activeBrand, -0.34);
  static Color get blueMid =>
      isSaweriaClassic ? retroYellow : _shiftLightness(_activeBrand, -0.08);
  static Color get blueBorder =>
      isSaweriaClassic ? retroInk : _shiftLightness(_activeBrand, 0.02);
  static Color get blueAccent => _activeBrand;
  static Color get blueText =>
      isSaweriaClassic ? retroInk : _shiftLightness(_activeBrand, 0.24);
  static Color get blueMuted =>
      isSaweriaClassic ? retroBlue : _shiftLightness(_activeBrand, 0.14);
  static Color get primaryWeb => _activeBrand;

  // Text
  static Color get textPrimary {
    if (isSaweriaClassic) {
      return retroInk;
    }
    return isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
  }

  static Color get textSecondary {
    if (isSaweriaClassic) {
      return const Color(0xFF5F5549);
    }
    return isDark ? const Color(0xFFA6ABB4) : const Color(0xFF334155);
  }

  static Color get textMuted {
    if (isSaweriaClassic) {
      return const Color(0xFF7C7165);
    }
    return isDark ? const Color(0xFF6B7280) : const Color(0xFF64748B);
  }

  static Color get textDim {
    if (isSaweriaClassic) {
      return const Color(0xFFA99E92);
    }
    return isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8);
  }

  // Semantic
  static const income = Color(0xFF10B981);
  static const greenSuccess = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
  static Color get border {
    if (isSaweriaClassic) {
      return retroInk;
    }
    return isDark ? const Color(0xFF1E2130) : const Color(0xFFE2E8F0);
  }

  static Color get borderAccent {
    if (isSaweriaClassic) {
      return retroInk;
    }
    return isDark ? const Color(0xFF2A2D3E) : const Color(0xFFCBD5E1);
  }
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
        backgroundColor:
            AppColors.isSaweriaClassic ? AppColors.bgCardAlt : AppColors.bg,
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
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 8 : 16),
          side: BorderSide(
            color: AppColors.border,
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueMid,
          foregroundColor: AppColors.blueText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 14),
            side: BorderSide(
              color: AppColors.blueBorder,
              width: AppColors.isSaweriaClassic ? 2.5 : 1,
            ),
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
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.borderAccent,
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.borderAccent,
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.blueBorder,
            width: AppColors.isSaweriaClassic ? 3 : 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        backgroundColor:
            AppColors.isSaweriaClassic ? AppColors.bgCardAlt : Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.isSaweriaClassic
              ? AppColors.retroInk
              : const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.isSaweriaClassic ? AppColors.bgCard : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 8 : 16),
          side: BorderSide(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFFE2E8F0),
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueMid,
          foregroundColor: AppColors.blueText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 14),
            side: BorderSide(
              color: AppColors.blueBorder,
              width: AppColors.isSaweriaClassic ? 2.5 : 1,
            ),
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
        fillColor: AppColors.isSaweriaClassic ? AppColors.bgCard : Colors.white,
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFFE2E8F0),
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFFE2E8F0),
            width: AppColors.isSaweriaClassic ? 2.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppColors.isSaweriaClassic ? 50 : 12),
          borderSide: BorderSide(
            color: AppColors.blueBorder,
            width: AppColors.isSaweriaClassic ? 3 : 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFF0F172A),
            fontSize: 36,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        headlineMedium: TextStyle(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w400,
            fontFamily: 'DMSerifDisplay'),
        titleLarge: TextStyle(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            color: AppColors.isSaweriaClassic
                ? AppColors.retroInk
                : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(
          color: AppColors.isSaweriaClassic
              ? AppColors.retroInk
              : const Color(0xFF0F172A),
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.isSaweriaClassic
              ? const Color(0xFF5F5549)
              : const Color(0xFF475569),
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: AppColors.isSaweriaClassic
              ? const Color(0xFF7C7165)
              : const Color(0xFF64748B),
          fontSize: 11,
          letterSpacing: 0.8,
        ),
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
