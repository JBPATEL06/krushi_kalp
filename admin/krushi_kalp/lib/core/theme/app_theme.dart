import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      onPrimary: Colors.white,
      secondary: isDark ? AppColorsV2.secondaryDark : AppColorsV2.secondary,
      onSecondary: Colors.white,
      surface: isDark ? AppColorsV2.surfaceDark : AppColorsV2.surface,
      background: isDark ? AppColorsV2.backgroundDark : AppColorsV2.background,
      error: const Color(0xFFEF4444),
      tertiary: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF10B981),
      onTertiary: Colors.white,
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
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      // ── Drawer/Sidebar Theme ──
      drawerTheme: DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      // ── Navigation ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: colorScheme.primary.withOpacity(0.1),
        elevation: 1,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
              color: colorScheme.outline.withOpacity(isDark ? 0.15 : 0.3)),
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
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Inter'),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(isDark ? 0.2 : 0.4),
        contentPadding: EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colors) {
    // We'll use Inter as it's the professional choice for dashboards
    final base = ThemeData(brightness: colors.brightness).textTheme;
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      displayMedium: base.displayMedium
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      displaySmall: base.displaySmall
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      headlineLarge: base.headlineLarge
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      headlineMedium: base.headlineMedium
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      headlineSmall: base.headlineSmall
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
      titleLarge: base.titleLarge
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: colors.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: colors.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      labelLarge: base.labelLarge
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium
          ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(
          color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
    );
  }
}
