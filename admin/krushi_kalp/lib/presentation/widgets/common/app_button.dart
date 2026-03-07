import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final IconData? icon;
  final double? width;
  final double? height;
  final double? fontSize;
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.icon,
    this.width,
    this.height,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final content = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary
                    ? colorScheme.onPrimary
                    : colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: (fontSize ?? 16) * 1.2),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: fontSize ?? 15,
                  fontWeight: FontWeight.w700,
                  color: _getTextColor(colorScheme, isDark),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    final borderRadius = BorderRadius.circular(AppRadius.lg);
    final double minWidth = width != null ? 0.0 : double.infinity;
    final minimumSize = Size(minWidth, height ?? 52.0);

    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: width,
          height: height ?? 52.0,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: content,
          ),
        );

      case AppButtonType.secondary:
        return SizedBox(
          width: width,
          height: height ?? 52.0,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  color ?? colorScheme.surfaceVariant.withOpacity(0.5),
              foregroundColor: colorScheme.onSurface,
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: content,
          ),
        );

      case AppButtonType.outline:
        return SizedBox(
          width: width,
          height: height ?? 52.0,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? colorScheme.primary,
              side: BorderSide(
                color: (color ?? colorScheme.primary).withOpacity(0.5),
                width: 1.5,
              ),
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: content,
          ),
        );

      case AppButtonType.text:
        return SizedBox(
          width: width,
          height: height ?? 52.0,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: color ?? colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              minimumSize: minimumSize,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: content,
          ),
        );
    }
  }

  Color _getTextColor(ColorScheme colorScheme, bool isDark) {
    if (type == AppButtonType.primary) return colorScheme.onPrimary;
    return colorScheme.onSurface;
  }
}
