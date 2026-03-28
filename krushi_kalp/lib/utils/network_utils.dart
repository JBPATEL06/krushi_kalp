import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../data/services/download_service.dart';
import 'crashlytics_service.dart';

class NetworkUtils {
  /// Checks if the error is related to network connectivity.
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    final s = error.toString();

    if (error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }

    return s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('HandshakeException') ||
        s.contains('Connection timed out') ||
        s.contains('Network is unreachable');
  }

  /// Downloads a file from [url] and opens it using the system default app.
  /// This implementation follows "Giant MNC" standards:
  /// 1. Caching: Checks if file exists before downloading.
  /// 2. Memory Efficient: Uses HttpClient stream consolidation.
  /// 3. Zero-Friction: Uses app's temp directory to avoid permission issues.
  static Future<void> downloadAndOpen({
    required String url,
    required String fileName,
    String? userId,
    Function(String)? onStatus,
  }) async {
    try {
      String filePath;
      if (userId != null && userId.isNotEmpty) {
        // MNC Pattern: Use persistent user-sandboxed path for students
        filePath = await DownloadService().getLocalPath(fileName, userId: userId);
      } else {
        // MNC Pattern: Use app's temp directory for guest/admin mode (no perms needed)
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/$fileName';
      }

      final file = File(filePath);

      // 1. Check if file already exists in cache (MNC Pattern)
      if (await file.exists()) {
        onStatus?.call("Opening cached file...");
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception("Could not open file: ${result.message}");
        }
        return;
      }

      // 2. Download if not in cache
      onStatus?.call("Downloading...");
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);

      // 3. Open after download
      onStatus?.call("Opening file...");
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception("File was downloaded but could not be opened: ${result.message}");
      }
    } catch (e, stack) {
      debugPrint("Download Error: $e");
      
      // Giant MNC Pattern: Explicitly record to Crashlytics before rethrowing
      logError("downloadAndOpen", e, stack);

      if (e.toString().contains('MissingPluginException')) {
        throw Exception("New native plugin detected. Please FULL RESTART the app to continue.");
      }
      rethrow;
    }
  }

  static void logError(String source, dynamic error, [StackTrace? stackTrace]) {
    // Standard MNC-style error logging
    if (!isNetworkError(error)) {
      CrashlyticsService.instance.recordError(
        error, 
        stackTrace, 
        reason: 'network_utils_$source'
      );
      
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    } else {
      // Network errors are logged as breadcrumbs to avoid noise
      CrashlyticsService.instance.log('Network error in $source: ${error.toString()}');
    }
  }
}

