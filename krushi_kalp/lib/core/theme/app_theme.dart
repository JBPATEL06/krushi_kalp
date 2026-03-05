import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.getTextTheme(),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.neutral200),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide:
              const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.borderError),
        ),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 12,
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.neutral500);
        }),
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        selectedLabelTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.neutral500,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.neutral500),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.onPrimary,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.onSecondary,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        error: AppColorsDark.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme: AppTypography.getTextTheme(),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColorsDark.textPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColorsDark.border),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: const BorderSide(color: AppColorsDark.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide:
              const BorderSide(color: AppColorsDark.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColorsDark.borderError),
        ),
        hintStyle:
            const TextStyle(color: AppColorsDark.textDisabled, fontSize: 14),
        labelStyle:
            const TextStyle(color: AppColorsDark.textSecondary, fontSize: 14),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColorsDark.primary,
              fontSize: 12,
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColorsDark.neutral400,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColorsDark.primary);
          }
          return const IconThemeData(color: AppColorsDark.neutral400);
        }),
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.primary.withValues(alpha: 0.15),
        selectedLabelTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColorsDark.primary,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColorsDark.neutral400,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(color: AppColorsDark.primary),
        unselectedIconTheme:
            const IconThemeData(color: AppColorsDark.neutral400),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  OPTION A — Forest Sage  (Green #16A34A + Amber accent)
  //  Switch in main.dart: theme: AppTheme.themeOptionA, darkTheme: AppTheme.darkThemeOptionA
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get themeOptionA => _buildFromSeed(
        seedColor: const Color(0xFF16A34A), // Deep Forest Green
        accentColor: const Color(0xFFF59E0B), // Warm Amber
        brightness: Brightness.light,
      );

  static ThemeData get darkThemeOptionA => _buildFromSeed(
        seedColor: const Color(0xFF16A34A),
        accentColor: const Color(0xFFFBBF24),
        brightness: Brightness.dark,
        darkSurface: const Color(0xFF0A1A0F), // Very dark green
        darkBackground: const Color(0xFF061009),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  OPTION C — Indigo + Saffron  (#4F46E5 + #EA580C)  ← CURRENTLY ACTIVE
  //  Switch in main.dart: theme: AppTheme.themeOptionC, darkTheme: AppTheme.darkThemeOptionC
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get themeOptionC => _buildFromSeed(
        seedColor: const Color(0xFF4F46E5), // Indigo
        accentColor: const Color(0xFFEA580C), // Saffron-Orange
        brightness: Brightness.light,
      );

  static ThemeData get darkThemeOptionC => _buildFromSeed(
        seedColor: const Color(0xFF4F46E5),
        accentColor: const Color(0xFFF97316),
        brightness: Brightness.dark,
        darkSurface: const Color(0xFF1E1B4B), // Deep Indigo surface
        darkBackground: const Color(0xFF13113A), // Deepest indigo
      );

  // ── Internal builder ─────────────────────────────────────────────────────

  static ThemeData _buildFromSeed({
    required Color seedColor,
    required Color accentColor,
    required Brightness brightness,
    Color? darkSurface,
    Color? darkBackground,
  }) {
    final isDark = brightness == Brightness.dark;

    // Let Flutter generate the full M3 palette from the seed
    var scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    // Override surface/background for dark themes + inject saffron as tertiary
    scheme = scheme.copyWith(
      tertiary: accentColor,
      tertiaryContainer: accentColor.withValues(alpha: 0.15),
      onTertiary: Colors.white,
      surface: isDark ? (darkSurface ?? scheme.surface) : scheme.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? (darkBackground ?? scheme.surface) : scheme.surface,
      textTheme: AppTypography.getTextTheme(),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? (darkSurface ?? scheme.surface) : Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // Card
      cardTheme: CardThemeData(
        color: isDark ? (darkSurface ?? scheme.surface) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(
            color: isDark
                ? scheme.outline.withValues(alpha: 0.4)
                : scheme.outline.withValues(alpha: 0.25),
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button — uses primary (seed color)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
        labelStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? (darkSurface ?? scheme.surface) : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
              fontSize: 12,
            );
          }
          return TextStyle(
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary);
          }
          return IconThemeData(color: scheme.onSurface.withValues(alpha: 0.6));
        }),
      ),
    );
  }
}
