import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette - Classic Blue & White
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryActive = Color(0xFF1E40AF);
  static const Color onPrimary = Colors.white;

  static const Color secondary = Color(0xFF64748B); // Cool Slate Slate
  static const Color onSecondary = Colors.white;

  // Neutral Palette (Clean Gray/Slate)
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Surface Colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color overlay = Color(0x660F172A);

  // Borders
  static const Color border = neutral200;
  static const Color borderFocus = primary;
  static const Color borderError = error;

  // Text
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textDisabled = neutral400;
}

// ── Dark Mode Palette ─────────────────────────────────────────────────────────
class AppColorsDark {
  // Brand — same primary blue in dark mode
  static const Color primary =
      Color(0xFF3B82F6); // slightly lighter for contrast
  static const Color primaryHover = Color(0xFF2563EB);
  static const Color onPrimary = Colors.white;

  static const Color secondary = Color(0xFF94A3B8);
  static const Color onSecondary = Colors.white;

  // Dark surfaces (navy scale)
  static const Color background = Color(0xFF0F172A); // deepest
  static const Color surface = Color(0xFF1E293B); // card / sheet
  static const Color surfaceHigh = Color(0xFF273549); // elevated card

  // Neutral scale — inverted for dark
  static const Color neutral50 = Color(0xFF273549);
  static const Color neutral100 = Color(0xFF334155);
  static const Color neutral200 = Color(0xFF475569);
  static const Color neutral300 = Color(0xFF64748B);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFFCBD5E1);
  static const Color neutral600 = Color(0xFFE2E8F0);
  static const Color neutral700 = Color(0xFFF1F5F9);
  static const Color neutral800 = Color(0xFFF8FAFC);
  static const Color neutral900 = Colors.white;

  // Semantic — slightly brighter for dark backgrounds
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Borders
  static const Color border = Color(0xFF334155);
  static const Color borderFocus = primary;
  static const Color borderError = error;

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = neutral400;
  static const Color textDisabled = neutral300;

  // Overlay
  static const Color overlay = Color(0xCC0F172A);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
