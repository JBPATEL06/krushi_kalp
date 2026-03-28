import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Industry-standard responsive helper for Krushi Kalp.
///
/// Breakpoints (from GEMINI.md):
///   Mobile  : 0   – 450
///   Tablet  : 451 – 800
///   Desktop : 801+
///
/// The context.sp/w/h extensions below maintain backward-compatible
/// signatures so zero call-site edits are needed after migration.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile;

  static bool isTablet(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isTablet;

  static bool isDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isDesktop;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.of(context).isDesktop) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveBreakpoints.of(context).isTablet) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Responsive context extensions.
/// These maintain 100% backward-compatible signatures — no call-site edits needed.
extension ResponsiveContext on BuildContext {
  /// Returns a responsive value based on the current breakpoint.
  /// Example: context.sp(14) returns 14 on mobile, 15 on tablet, 16 on desktop.
  double sp(double size) {
    final bp = ResponsiveBreakpoints.of(this);
    if (bp.isDesktop) return size * 1.15;
    if (bp.isTablet) return size * 1.08;
    return size; // Mobile: return as-is (design is mobile-first at 375px)
  }

  /// Responsive width scaling. Returns the value scaled for the current breakpoint.
  double w(double width) {
    final bp = ResponsiveBreakpoints.of(this);
    if (bp.isDesktop) return width * 1.15;
    if (bp.isTablet) return width * 1.08;
    return width;
  }

  /// Responsive height scaling. Returns the value scaled for the current breakpoint.
  double h(double height) {
    final bp = ResponsiveBreakpoints.of(this);
    if (bp.isDesktop) return height * 1.12;
    if (bp.isTablet) return height * 1.06;
    return height;
  }

  /// Percentage-based height: hp(50) = 50% of screen height.
  double hp(double percent) =>
      MediaQuery.sizeOf(this).height * (percent / 100);

  /// Percentage-based width: wp(50) = 50% of screen width.
  double wp(double percent) =>
      MediaQuery.sizeOf(this).width * (percent / 100);

  /// True when on Tablet breakpoint (451–800px).
  bool get isTablet => ResponsiveBreakpoints.of(this).isTablet;

  /// True when on Desktop breakpoint (801px+).
  bool get isDesktop => ResponsiveBreakpoints.of(this).isDesktop;

  /// True when on Mobile breakpoint (0–450px).
  bool get isMobile => ResponsiveBreakpoints.of(this).isMobile;
}
