import 'package:flutter/material.dart';
export 'package:krushi_kalp/utils/responsive.dart';

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

// Extensions moved to lib/utils/responsive.dart
