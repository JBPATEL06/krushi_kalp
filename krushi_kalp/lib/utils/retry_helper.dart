import 'dart:async';
import 'network_utils.dart';

/// Wraps any async call with automatic retry on network errors.
///
/// Usage:
/// ```dart
/// final tests = await RetryHelper.run(() => _supabase.from('mock_tests').select());
/// ```
class RetryHelper {
  /// Retries [action] up to [maxRetries] times on network failure.
  /// Uses exponential backoff: 1s â†’ 2s â†’ 4s between retries.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        final isNetwork = NetworkUtils.isNetworkError(e);

        if (!isNetwork || attempt > maxRetries) {
          // Not a network error or exhausted retries — rethrow
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s...
        final delay = initialDelay * (1 << (attempt - 1));
        
        await Future.delayed(delay);
      }
    }
  }
}
