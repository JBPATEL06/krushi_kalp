import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// A centralized service to manage Firebase Crashlytics.
/// Handles initialization, user tagging, breadcrumb logging, and error reporting.
class CrashlyticsService {
  // Singleton
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  static CrashlyticsService get instance => _instance;

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initializes Crashlytics configuration.
  Future<void> init() async {
    // In debug mode, we might want to disable collection to avoid cluttering the console.
    // However, for testing the integration, we can leave it enabled or toggle it here.
    if (kDebugMode) {
      // For development: You can toggle this to true to test your integration.
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      debugPrint('CrashlyticsService: Collection enabled in Debug Mode');
    } else {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    }
  }

  /// Sets the user identifier for crash reports.
  /// Call this after a successful login.
  Future<void> setUser(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      log('User attributed: $userId');
    } catch (e) {
      debugPrint('CrashlyticsService: Error setting user identifier: $e');
    }
  }

  /// Clears the user identifier.
  /// Call this during logout.
  Future<void> clearUser() async {
    try {
      await _crashlytics.setUserIdentifier('');
      log('User identifier cleared');
    } catch (e) {
      debugPrint('CrashlyticsService: Error clearing user identifier: $e');
    }
  }

  /// Adds a custom log message (breadcrumb) to the next crash report.
  void log(String message) {
    debugPrint('Crashlytics [LOG]: $message');
    _crashlytics.log(message);
  }

  /// Records a non-fatal error to Crashlytics.
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('CrashlyticsService: Error recording error: $e');
    }
  }
}
