import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

/// Wraps form content in a standardized "Premium Card"
Widget buildFormCard(BuildContext context,
    {required Widget child, EdgeInsetsGeometry? padding}) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    padding: padding ?? EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
      border: Border.all(
          color: colorScheme.outline.withOpacity(isDark ? 0.1 : 0.2)),
    ),
    child: child,
  );
}

/// Shows a standardized "Premium" Dialog
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  String? confirmText,
  VoidCallback? onConfirm,
  bool isDestructive = false,
  List<Widget>? actions,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ) ??
                  const TextStyle(),
              child: content,
            ),
            SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions ??
                  [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancel'),
                    ),
                    if (confirmText != null) ...[
                      SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: () {
                          if (onConfirm != null) onConfirm();
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive
                              ? colorScheme.errorContainer
                              : colorScheme.primary,
                          foregroundColor: isDestructive
                              ? colorScheme.onErrorContainer
                              : colorScheme.onPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(confirmText),
                      ),
                    ],
                  ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Returns a standardized "Premium" Input Decoration
InputDecoration getPremiumInputDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
    contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
    floatingLabelStyle:
        TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    ),
  );
}

/// Extracts a clean filename from a full Supabase URL or local path
String extractFilename(String? path) {
  if (path == null || path.isEmpty) return 'No file selected';
  try {
    // If it's a URL, get the last segment before query params
    final uri = Uri.parse(path);
    final lastSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : path;

    // Remove common Supabase prefixes if present in filename
    return lastSegment.split('/').last.split('_').last;
  } catch (e) {
    // If parsing fails, just show a truncated version
    return truncateText(path, 30);
  }
}

/// Truncates long text with ellipses
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}
