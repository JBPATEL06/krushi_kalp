import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized utility for translating technical database errors into
/// logical, user-friendly instructions for administrators.
class DbErrorHelper {
  /// Translates an error (likely a PostgrestException) into a human-readable message.
  static String translateError(dynamic error, {String itemName = 'item'}) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23503': // Foreign Key Constraint
          return 'Cannot delete this $itemName because it is linked to other records (e.g., users have purchased it). Try deactivating or hiding it instead.';

        case '23505': // Unique Constraint
          return 'An entry with this unique information already exists. Please check for duplicates.';

        case '23502': // Not Null Violation
          return 'Required information is missing. Please ensure all mandatory fields are filled.';

        case '23514': // Check Constraint
          return 'One or more values do not meet the required rules (e.g., price must be greater than 0).';

        case '42804': // Data Type Mismatch
          return 'Input format is incorrect. Please check that you entered numbers and text correctly.';

        case '42501': // RLS / Permission
          return 'Access Denied: You do not have permission to modify this data.';

        default:
          return 'Database Error (${error.code}): ${error.message}';
      }
    }

    // Fallback for non-Postgrest errors
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network Error: Please check your internet connection and try again.';
    }

    if (errorStr.contains('timeout')) {
      return 'Operation timed out. The server might be busy, please try again later.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
