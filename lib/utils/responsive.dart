import 'package:flutter/material.dart';

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

  // Screen size breakpoints
  static const double mobileWidth = 600;
  static const double tabletWidth = 1100;

  // Helper methods to check screen size
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileWidth &&
      MediaQuery.of(context).size.width < tabletWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletWidth) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= mobileWidth) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
