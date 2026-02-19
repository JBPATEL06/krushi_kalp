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
