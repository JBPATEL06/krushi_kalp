import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/network_utils.dart';

class ErrorService {
  ErrorService._();
  static final ErrorService instance = ErrorService._();

  /// Translates a technical error into a beautiful, user-friendly message.
  String getBeautifulError(dynamic error) {
    if (error == null) return "Something went wrong. Please try again.";

    // 1. Network Errors
    if (NetworkUtils.isNetworkError(error)) {
      return "Connection lost! ?? Please check your internet. I'll be here waiting when you're back online.";
    }

    final String errorStr = error.toString();
    final String lowercaseError = errorStr.toLowerCase();

    // 2. Auth Errors
    if (error is AuthException ||
        lowercaseError.contains('authapiexception') ||
        lowercaseError.contains('authexception')) {
      
      // Specifically check for account conflicts
      if (lowercaseError.contains('user already exists') || 
          lowercaseError.contains('user already registered') ||
          lowercaseError.contains('user_already_exists')) {
        return "It looks like you've been here before! This email is already registered. Try signing in instead.";
      }
      
      if (lowercaseError.contains('provider already linked') ||
          lowercaseError.contains('already been used') ||
          lowercaseError.contains('setup a password') ||
          lowercaseError.contains('provider_already_linked')) {
        return "Different account found! This email is already linked to another login method (like Google). Please sign in using that method.";
      }

      if (lowercaseError.contains('invalid login credentials') ||
          lowercaseError.contains('invalid credentials')) {
        return "Oops! The email or password doesn't seem right. Please double-check and try again.";
      }
      
      if (lowercaseError.contains('email not confirmed')) {
        return "Almost there! Your email needs a quick confirmation. Please check your inbox for a verification link.";
      }

      if (error is AuthException) return error.message;
    }

    // 3. Database Errors (Postgrest)
    if (error is PostgrestException) {
      switch (error.code) {
        case '23503': // Foreign Key
          return "This item is currently 'popular'! ?? It's linked to other active records (like user purchases), so it can't be deleted right now.";
        case '23505': // Unique Constraint
          return "Duplicate alert! ?? Something with this exact information already exists.";
        case '23502': // Not Null
          return "Missing information. ?? Please fill in all the required fields.";
        default:
          return error.message;
      }
    }

    // 4. Storage Errors
    if (lowercaseError.contains('payload too large')) {
      return "File too large! ??? Please pick something a bit smaller to keep things moving smoothly.";
    }
    if (lowercaseError.contains('invalid file type')) {
      return "Invalid format. ?? I only accept PDFs for this one!";
    }

    // 5. Common String Matches
    if (lowercaseError.contains('timeout')) {
      return "The server is taking a little nap. ? Please try again in a moment!";
    }

    if (lowercaseError.contains('missingpluginexception')) {
      return "Build Update Required! 🧱 A new native plugin was recently added. Please completely HALT the app and run 'flutter run' to sync correctly.";
    }

    // 6. Generic Fallback
    if (error is String) return error;
    return "Something went wrong. Please try again.";
  }
}
