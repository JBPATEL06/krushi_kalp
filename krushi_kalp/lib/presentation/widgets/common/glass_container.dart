import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppRadius.xxl;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color:
                  (isDark ? Colors.black : Colors.white).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color:
                    borderColor ?? (isDark ? Colors.white12 : Colors.white24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
