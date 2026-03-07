import 'package:flutter/material.dart';

/// Wraps form content in a standardized "Premium Card"
Widget buildFormCard(BuildContext context,
    {required Widget child, EdgeInsetsGeometry? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
      border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
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
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              child: content,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions ??
                  [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancel'),
                    ),
                    if (confirmText != null) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (onConfirm != null) onConfirm();
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                          foregroundColor: isDestructive
                              ? Theme.of(context).colorScheme.onError
                              : Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor:
        Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500),
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
    floatingLabelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
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
