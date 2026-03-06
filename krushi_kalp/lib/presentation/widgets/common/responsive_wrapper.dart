import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final Size designSize;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.designSize = const Size(375, 812), // Standard iPhone X/11 design size
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('ResponsiveWrapper: Building...');
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final isPortrait = mediaQuery.orientation == Orientation.portrait;

        // Calculate scale factor based on width for consistency
        // (Assuming width is the primary constraint for mobile layouts)
        final double scaleFactor = isPortrait
            ? constraints.maxWidth / designSize.width
            : constraints.maxHeight /
                designSize.width; // Use height as width in landscape roughly

        // Cap scale factor to avoid overly large elements on tablets
        final double effectiveScale = scaleFactor > 1.2 ? 1.2 : scaleFactor;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(effectiveScale),
            // We store the scale factor in a custom attribute if possible,
            // but for simplicity, we'll just use textScaler's factor or a helper.
          ),
          child: child,
        );
      },
    );
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }
}

// Extension for easy access to responsive sizes
extension ResponsiveContext on BuildContext {
  double get scaleFactor {
    final width = MediaQuery.of(this).size.width;
    final designWidth = 375.0; // Standard design width
    final scale = width / designWidth;
    return scale > 1.2 ? 1.2 : scale;
  }

  double sp(double size) =>
      size * scaleFactor * 0.9; // Scaled pixels with 10% reduction
  double w(double width) => width * scaleFactor * 0.9;
  double h(double height) => height * scaleFactor * 0.9;

  bool get isTablet => MediaQuery.of(this).size.width > 600;
  bool get isDesktop => MediaQuery.of(this).size.width > 1200;
}
