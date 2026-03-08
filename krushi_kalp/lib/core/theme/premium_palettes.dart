import 'package:flutter/material.dart';

/// 🌌 ANTI-GRAVITY Identity Standard: Premium Color Tokens
/// "Clarity Defines Structure. Design Defines Trust."

class PremiumPalettes {
  // ── Indigo + Saffron (High-Trust Light Theme) ──
  static const Color indigoPrimary = Color(0xFF1E1B4B); // Deep Academic Navy
  static const Color saffronAccent = Color(0xFFF59E0B); // Vibrant Saffron
  static const Color slateSecondary = Color(0xFF475569); // Professional Slate
  static const Color cloudBackground = Color(0xFFF8FAFC); // Clean Surface

  // ── Neutral + Indigo (Premium Gray Dark Theme) ──
  static const Color neutralDarkBackground =
      Color(0xFF121212); // Deep Neutral Gray
  static const Color neutralDarkSurface = Color(0xFF1E1E1E); // Surface Gray
  static const Color indigoDarkPrimary = Color(0xFF818CF8); // Indigo 400
  static const Color skyDarkSecondary = Color(0xFF38BDF8); // Sky 400
}

class AppColorsV2 {
  // ── Light Theme (Indigo + Saffron) ──
  static const Color primary = PremiumPalettes.indigoPrimary;
  static const Color secondary = PremiumPalettes.saffronAccent;
  static const Color background = PremiumPalettes.cloudBackground;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  // ── Dark Theme (Neutral + Indigo) ──
  static const Color primaryDark = PremiumPalettes.indigoDarkPrimary;
  static const Color secondaryDark = PremiumPalettes.skyDarkSecondary;
  static const Color backgroundDark = PremiumPalettes.neutralDarkBackground;
  static const Color surfaceDark = PremiumPalettes.neutralDarkSurface;
  static const Color textPrimaryDark = Color(0xFFF5F5F5); // Neutral 100
  static const Color textSecondaryDark = Color(0xFFA3A3A3); // Neutral 400
}
