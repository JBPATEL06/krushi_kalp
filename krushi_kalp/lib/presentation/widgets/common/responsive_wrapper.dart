import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Re-export so existing imports of this file still get the Responsive class
// and context extensions without changing any import statements.
export 'package:krushi_kalp/utils/responsive.dart';

/// Legacy passthrough widget — the actual responsive behavior is now
/// provided by ResponsiveBreakpoints.builder() in main.dart.
/// This class is kept for backward-compatibility only.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    // Kept for backward compatibility — ignored, layout is now handled
    // by responsive_framework at the app level.
    Size designSize = const Size(375, 812),
  });

  @override
  Widget build(BuildContext context) {
    // No more TextScaler manipulation — responsive_framework handles layout.
    return child;
  }

  /// Deprecated: Use [ResponsiveBreakpoints.of(context).isTablet] instead.
  @Deprecated('Use ResponsiveBreakpoints.of(context).isTablet')
  static bool isWide(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isTablet;

  /// Deprecated: Use [ResponsiveBreakpoints.of(context).isDesktop] instead.
  @Deprecated('Use ResponsiveBreakpoints.of(context).isDesktop')
  static bool isDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isDesktop;
}
