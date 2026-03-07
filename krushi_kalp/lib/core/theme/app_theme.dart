import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'premium_palettes.dart';
import 'app_spacing.dart';
import 'app_radius.dart';
import 'app_motion.dart';

/// 🌌 ANTI-GRAVITY Unified Theme (v2.0)
/// "Clarity Defines Structure. Design Defines Trust."
class AppTheme {
  AppTheme._();

  // ── Theme Data ──
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // ── Standard Tokens (Static Access) ──
  static const spacing = AppSpacing;
  static const radius = AppRadius;
  static const motion = AppMotion;

  // Note: For colors that adapt to theme, use Theme.of(context).colorScheme
  // For raw token access, use the relevant Palette/Colors class.
  static const colors = AppColorsV2;

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: isDark ? AppColorsV2.primaryDark : AppColorsV2.primary,
      brightness: brightness,
      primary: isDark ? AppColorsV2.primaryDark : AppColorsV2.primary,
      onPrimary: isDark ? AppColorsV2.backgroundDark : Colors.white,
      secondary: isDark ? AppColorsV2.secondaryDark : AppColorsV2.secondary,
      onSecondary: isDark ? AppColorsV2.backgroundDark : Colors.white,
      surface: isDark ? AppColorsV2.surfaceDark : AppColorsV2.surface,
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white, // ← Critical for visibility on red buttons
      outline: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      outlineVariant:
          isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );

    final scaffoldColor =
        isDark ? AppColorsV2.backgroundDark : AppColorsV2.background;
    final surfaceColor = colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: scaffoldColor,
      cardColor: surfaceColor,
      dividerColor: colorScheme.outlineVariant,

      // ── Typography ──
      textTheme: _buildTextTheme(colorScheme),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        toolbarHeight: 64,
      ),

      // ── Navigation ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primary.withOpacity(0.12),
        elevation: 3,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary);
          }
          return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant);
        }),
      ),

      // ── Cards & Surfaces ──
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
              color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.all(AppSpacing.xs),
      ),

      // ── Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceVariant.withOpacity(0.3)
            : colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colors) {
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: colors.onSurface),
      displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: colors.onSurface),
      displaySmall: TextStyle(
          fontSize: 36, fontWeight: FontWeight.w700, color: colors.onSurface),
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: colors.onSurface,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: colors.onSurface),
      headlineSmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: colors.onSurface),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: colors.onSurface),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
      bodyLarge: TextStyle(fontSize: 16, color: colors.onSurface, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: colors.onSurface, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant),
    );
  }
}
