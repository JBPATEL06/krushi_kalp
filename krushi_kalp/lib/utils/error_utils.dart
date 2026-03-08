import 'package:flutter/material.dart';
import '../data/services/error_service.dart';

class ErrorUtils {
  /// Displays a user-friendly error message in a SnackBar.
  static void showError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    final message = ErrorService.instance.getBeautifulError(error);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
