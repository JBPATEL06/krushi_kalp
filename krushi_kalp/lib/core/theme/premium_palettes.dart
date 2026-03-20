import 'package:flutter/material.dart';

/// 🌌 ANTI-GRAVITY Identity Standard: Premium Color Tokens
/// "Clarity Defines Structure. Design Defines Trust."

class PremiumPalettes {
  // ── Indigo + Slate (Light Theme) ──
  static const Color indigoPrimary = Color(0xFF1E1B4B); 
  static const Color slateBackground = Color(0xFFF8FAFC);
  static const Color slateSurface = Colors.white;

  // ── Slate + Teal (Dark Theme - Reference Image 1) ──
  static const Color slateDarkBackground = Color(0xFF0F172A); // Slate 900
  static const Color slateDarkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color tealAccent = Color(0xFF2DD4BF);         // Teal 400
  static const Color skyAccent = Color(0xFF38BDF8);          // Sky 400
}

class AppColorsV2 {
  // ── Light Theme ──
  static const Color primary = PremiumPalettes.indigoPrimary;
  static const Color secondary = Color(0xFF4F46E5); // Indigo 600
  static const Color background = PremiumPalettes.slateBackground;
  static const Color surface = PremiumPalettes.slateSurface;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color tertiary = Color(0xFFF59E0B); // Amber

  // ── Dark Theme ──
  static const Color primaryDark = PremiumPalettes.tealAccent;
  static const Color secondaryDark = PremiumPalettes.skyAccent;
  static const Color tertiaryDark = Color(0xFFFACC15); // Saffron/Yellow
  static const Color backgroundDark = PremiumPalettes.slateDarkBackground;
  static const Color surfaceDark = PremiumPalettes.slateDarkSurface;
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
}
