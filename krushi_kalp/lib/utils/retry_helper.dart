import 'dart:async';
import 'network_utils.dart';
import '../utils/crashlytics_service.dart';

/// Wraps any async call with automatic retry on network errors.
///
/// Usage:
/// ```dart
/// final tests = await RetryHelper.run(() => _supabase.from('mock_tests').select());
/// ```
class RetryHelper {
  /// Retries [action] up to [maxRetries] times on network failure.
  /// Uses exponential backoff: 1s -> 2s -> 4s between retries.
  /// Enforces a hard [timeout] on the actual request to prevent hanging.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(seconds: 1),
    Duration? maxDelay,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await action().timeout(timeout);
      } catch (e, stack) {
        attempt++;
        final isNetwork = NetworkUtils.isNetworkError(e) || e is TimeoutException;

        if (!isNetwork || attempt > maxRetries) {
          // Log final failure to Crashlytics
          CrashlyticsService.instance.recordError(e, stack, reason: 'retry_helper_failed_after_$attempt\_attempts');
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s...
        var delay = initialDelay * (1 << (attempt - 1));
        if (maxDelay != null && delay > maxDelay) {
          delay = maxDelay;
        }

        // Print to console for real-time visibility during user testing
        // ignore: avoid_print
        print('RetryHelper: Attempt $attempt failed. Retrying in ${delay.inSeconds}s... (Error: $e)');
        
        await Future.delayed(delay);
      }
    }
  }
}
