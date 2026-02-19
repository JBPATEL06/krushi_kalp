import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Represents the current state of a download
enum DownloadStatus {
  idle,
  downloading,
  completed,
  error,
  cancelled,
}

/// Progress information for a download
class DownloadProgress {
  final int bytesReceived;
  final int totalBytes;
  final double percentage;
  final DownloadStatus status;
  final String? errorMessage;

  DownloadProgress({
    required this.bytesReceived,
    required this.totalBytes,
    required this.percentage,
    required this.status,
    this.errorMessage,
  });

  bool get isComplete => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get hasError => status == DownloadStatus.error;
}

class DownloadService {
  // Singleton
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Returns the local path where a file should be stored
  /// Using ApplicationDocumentsDirectory for security (not visible to user)
  Future<String> getLocalPath(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    // Sanitize filename to prevent directory traversal
    final sanitizedFilename = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    return '${directory.path}/$sanitizedFilename';
  }

  /// Checks if a file exists locally
  Future<bool> isFileDownloaded(String filename) async {
    try {
      final path = await getLocalPath(filename);
      return File(path).exists();
    } catch (e) {
      debugPrint("Error checking file existence: $e");
      return false;
    }
  }

  /// Downloads a file with progress tracking via Stream
  /// Returns a Stream of DownloadProgress events
  Stream<DownloadProgress> downloadFileWithProgress(
      String url, String filename) async* {
    try {
      final path = await getLocalPath(filename);
      final file = File(path);

      // Check if file already exists
      if (await file.exists()) {
        debugPrint("File already exists: $path");
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: DownloadStatus.completed,
        );
        return;
      }

      debugPrint("Starting download: $url -> $path");

      // Start download
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 0.0,
          status: DownloadStatus.error,
          errorMessage: "HTTP ${response.statusCode}",
        );
        return;
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = file.openWrite();

      // Stream download progress
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final percentage =
            contentLength > 0 ? (receivedBytes / contentLength * 100) : 0.0;

        yield DownloadProgress(
          bytesReceived: receivedBytes,
          totalBytes: contentLength,
          percentage: percentage,
          status: DownloadStatus.downloading,
        );
      }

      await sink.close();
      debugPrint("Download complete: $path");

      yield DownloadProgress(
        bytesReceived: receivedBytes,
        totalBytes: contentLength,
        percentage: 100.0,
        status: DownloadStatus.completed,
      );
    } catch (e) {
      debugPrint("Download error: $e");
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Downloads a file from [url] and saves it as [filename]
  /// Returns the path if successful, throws error otherwise
  /// (Legacy method - kept for backward compatibility)
  Future<String> downloadFile(String url, String filename,
      {Function(double)? onProgress}) async {
    try {
      final path = await getLocalPath(filename);
      final file = File(path);

      if (await file.exists()) {
        debugPrint("File already exists: $path");
        return path;
      }

      debugPrint("Starting download: $url -> $path");
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
            "Download failed with status code: ${response.statusCode}");
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (contentLength > 0 && onProgress != null) {
            onProgress(receivedBytes / contentLength);
          }
        },
        onDone: () async {
          await sink.close();
        },
        onError: (e) {
          sink.close();
          throw e; // Re-throw to handle in UI
        },
        cancelOnError: true,
      ).asFuture();

      debugPrint("Download complete: $path");
      return path;
    } catch (e) {
      debugPrint("Download error: $e");
      rethrow;
    }
  }

  /// Deletes a file from device storage
  Future<void> deleteFile(String filename) async {
    try {
      final path = await getLocalPath(filename);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint("File deleted: $path");
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
      rethrow;
    }
  }
}
