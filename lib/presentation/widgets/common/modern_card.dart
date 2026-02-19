import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:krushi_kalp/core/theme/app_colors.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool animate;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.onTap,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200.withOpacity(0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    if (animate) {
      return card
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
    }

    return card;
  }
}
