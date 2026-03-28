import 'package:flutter/material.dart';
import '../../../core/theme/app_radius.dart';

enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final IconData? icon;
  final double? width;
  final double? height; // NEW
  final double? fontSize; // NEW
  final Color? color;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.icon,
    this.width,
    this.height, // NEW
    this.fontSize, // NEW
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    final content = isLoading
        ? SizedBox(
            width: (height ?? 56) * 0.4, // Scale loader
            height: (height ?? 56) * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: (fontSize ?? 16) * 1.25),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final borderRadius = BorderRadius.circular(AppRadius.lg);
    // If width is specified, don't force infinite width.
    final double minWidth = width != null ? 0.0 : double.infinity;
    // Use provided height or default 56
    final minimumSize = Size(minWidth, height ?? 56.0);

    final theme = Theme.of(context);

    // 2. Button Variant
    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: height != null
                  ? EdgeInsets.zero
                  : null, // Remove padding if fixed height
            ),
            child: content,
          ),
        );

      case AppButtonType.secondary:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              elevation: 0,
              padding: height != null ? EdgeInsets.zero : null,
            ),
            child: isLoading
                ? SizedBox(
                    width: (height ?? 56) * 0.4,
                    height: (height ?? 56) * 0.4,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : content,
          ),
        );

      case AppButtonType.outline:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? theme.colorScheme.primary,
              side: BorderSide(
                  color: color ?? theme.colorScheme.primary, width: 1.5),
              minimumSize: minimumSize,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: height != null ? EdgeInsets.zero : null,
            ),
            child: isLoading
                ? SizedBox(
                    width: (height ?? 56) * 0.4,
                    height: (height ?? 56) * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          color ?? theme.colorScheme.primary),
                    ),
                  )
                : content,
          ),
        );

      case AppButtonType.text:
        return SizedBox(
            width: width,
            height: height,
            child: TextButton(
              onPressed: isLoading ? null : onPressed,
              style: TextButton.styleFrom(
                foregroundColor: color ?? theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                minimumSize: minimumSize,
                padding: height != null ? EdgeInsets.zero : null,
              ),
              child: content,
            ));
    }
  }
}
