import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkUtils {
  /// Checks if the error is related to network connectivity.
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    final s = error.toString();

    // Check for common network exceptions
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }

    // Check for string signatures if exception type is wrapped or unknown
    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('HandshakeException') ||
        s.contains('Connection timed out') ||
        s.contains('Network is unreachable');
  }

  /// Logs the error as a warning if it's a network error, otherwise logs normally.
  static void logError(String source, dynamic error, [StackTrace? stackTrace]) {
    if (isNetworkError(error)) {
      
    } else {
      
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}
