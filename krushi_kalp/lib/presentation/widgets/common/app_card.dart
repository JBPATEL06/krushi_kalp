import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? elevation;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveColor = backgroundColor ?? colorScheme.surface;
    final effectiveRadius = borderRadius ?? AppRadius.lg;
    final effectivePadding = padding ?? EdgeInsets.all(AppSpacing.lg);

    return Container(
      margin: margin ?? EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: border ??
            Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05 * elevation!),
                  blurRadius: 10 * elevation!,
                  offset: Offset(0, 4 * elevation!),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
