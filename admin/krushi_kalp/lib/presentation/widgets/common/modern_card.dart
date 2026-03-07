import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool animate;
  final double? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
    this.animate = false,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveRadius = borderRadius ?? AppRadius.lg;

    final decoration = BoxDecoration(
      color: backgroundColor ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: Border.all(
        color: borderColor ?? colorScheme.outline.withOpacity(0.1),
        width: borderWidth ?? 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget content = Padding(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: content,
        ),
      );
    }

    Widget card = Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.only(bottom: AppSpacing.md),
      decoration: decoration,
      child: content,
    );

    if (animate) {
      return card
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
    }

    return card;
  }
}
