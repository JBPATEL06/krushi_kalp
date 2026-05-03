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

  FirebaseCrashlytics get _crashlytics {
    try {
      return FirebaseCrashlytics.instance;
    } catch (e) {
      // If Firebase isn't initialized, this will throw [core/no-app].
      // We catch it here to prevent the app from getting "stuck" in a crash loop.
      throw StateError('Firebase not initialized. Cannot access Crashlytics.');
    }
  }

  /// Initializes Crashlytics configuration and sets up global error catchers.
  Future<void> init() async {
    // Enable collection in both debug and release to capture integration issues.
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    // Attempt to send any unsent reports from previous runs (critical for non-fatals)
    await _crashlytics.sendUnsentReports();
    log('Crashlytics initialized and unsent reports flushed');

    // Automatically catch all Flutter framework errors
    FlutterError.onError = (errorDetails) {
      // Pass all uncaught errors to Crashlytics
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Automatically catch all asynchronous errors that aren't handled by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true; // Return true to indicate the error was handled
    };
  }

  /// Sets the user identifier for crash reports.
  /// Call this after a successful login.
  Future<void> setUser(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      log('User attributed: $userId');
    } catch (e) {
      debugPrint('Crashlytics set user error: $e');
    }
  }

  /// Clears the user identifier.
  /// Call this during logout.
  Future<void> clearUser() async {
    try {
      await _crashlytics.setUserIdentifier('');
      log('User identifier cleared');
    } catch (e) {
      debugPrint('Crashlytics clear user error: $e');
    }
  }

  /// Adds a custom log message (breadcrumb) to the next crash report.
  void log(String message) {
    
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
      debugPrint('Crashlytics record error failure: $e');
    }
  }
}
