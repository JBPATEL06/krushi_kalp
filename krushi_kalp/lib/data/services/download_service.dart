import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/supabase_url_helper.dart';
import '../../utils/crashlytics_service.dart';

/// A simple token used to signal cancellation of an ongoing download.
class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  /// Signals that the associated download should be aborted.
  void cancel() {
    _isCancelled = true;
  }
}

/// Status of a download task managed by [DownloadService].
enum DownloadStatus {
  idle,
  downloading,
  completed,
  error,
  cancelled,
}

/// Model representing a single download task.
class DownloadTask {
  final String taskId;
  final String testId;
  final String fileName;
  final String userId;
  final String storagePath;
  final String bucketName;
  final CancelToken cancelToken;
  DownloadStatus status;
  double progress; // 0.0 to 1.0

  DownloadTask({
    required this.taskId,
    required this.testId,
    required this.fileName,
    required this.userId,
    required this.storagePath,
    required this.bucketName,
    required this.cancelToken,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
  });
}

/// Progress information for a synchronous/streamed download.
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

/// A singleton service that manages file downloads into a per-user sandbox.
/// Supports background downloads with progress notifications and automatic cleanup.
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Map of currently active download tasks.
  final Map<String, DownloadTask> _activeTasks = {};

  // ── INTERNAL HELPERS ───────────────────────────────────────────────────────

  /// Returns the private, per-user storage directory.
  Future<Directory> _userDir(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError(
          'userId must not be empty — refusing to use shared directory');
    }
    final root = await getApplicationDocumentsDirectory();
    final safeId = userId.replaceAll(RegExp(r'[^\w-]'), '_');
    final dir = Directory('${root.path}/user_$safeId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the absolute path for a filename inside the user's directory.
  Future<String> getLocalPath(String filename, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError(
          'userId is required — always pass the authenticated user ID');
    }
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final dir = await _userDir(userId);
    return '${dir.path}/$sanitized';
  }

  /// Internal method to delete a partial or corrupted file.
  Future<void> _cleanupPartialFile(String fileName, String userId) async {
    try {
      final path = await getLocalPath(fileName, userId: userId);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        CrashlyticsService.instance
            .log('Cleaned up partial file: $fileName for user: $userId');
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason: 'Partial file cleanup failed: $fileName');
    }
  }

  // ── OWNERSHIP MANIFEST ─────────────────────────────────────────────────────

  Future<File> _manifestFile(String userId) async {
    final dir = await _userDir(userId);
    return File('${dir.path}/_manifest.json');
  }

  Future<Map<String, String>> _readManifest(String userId) async {
    try {
      final file = await _manifestFile(userId);
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'download_service');
      return {};
    }
  }

  Future<void> _writeManifest(
      String userId, Map<String, String> manifest) async {
    try {
      final file = await _manifestFile(userId);
      await file.writeAsString(json.encode(manifest));
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Manifest write failed for user: $userId');
    }
  }

  Future<void> _registerOwnership(String userId, String filename) async {
    final manifest = await _readManifest(userId);
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    manifest[sanitized] = userId;
    await _writeManifest(userId, manifest);
  }

  Future<bool> verifyOwnership(String filename,
      {required String userId}) async {
    if (userId.isEmpty) return false;
    final sanitized = filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final manifest = await _readManifest(userId);
    final owner = manifest[sanitized];
    return owner == userId;
  }

  // ── BACKGROUND DOWNLOAD ENGINE ─────────────────────────────────────────────

  /// Cancels all active downloads for a specific [userId].
  /// Usually called during logout or session mismatch.
  void cancelAllDownloadsForUser(String userId) {
    final userTasks =
        _activeTasks.values.where((t) => t.userId == userId).toList();
    for (final task in userTasks) {
      task.cancelToken.cancel();
      task.status = DownloadStatus.cancelled;
      CrashlyticsService.instance
          .log('Download aborted by service for task: ${task.taskId}');
    }
  }

  /// Downloads a file in the background with progress reporting and cancellation support.
  /// Uses direct file streaming (IOSink) to avoid memory accumulation (prevents OOM/ANRs).
  Future<void> downloadFileInBackground({
    required String testId,
    required String fileName,
    required String storagePath,
    required String bucketName,
    required String userId,
    required Function(double progress) onProgress,
    required Function(String localPath) onComplete,
    required Function(String error) onError,
    CancelToken? externalCancelToken,
  }) async {
    final taskId = '${userId}_$testId';
    final cancelToken = externalCancelToken ?? CancelToken();

    // Guard 1: Duplicate check
    if (_activeTasks.containsKey(taskId)) {
      CrashlyticsService.instance
          .log('Download already in progress for taskId: $taskId');
      return;
    }

    // Guard 2: Immediate cancellation check
    if (cancelToken.isCancelled) return;

    final task = DownloadTask(
      taskId: taskId,
      testId: testId,
      fileName: fileName,
      userId: userId,
      storagePath: storagePath,
      bucketName: bucketName,
      cancelToken: cancelToken,
      status: DownloadStatus.downloading,
    );
    _activeTasks[taskId] = task;

    IOSink? sink;
    try {
      // Step 1: Sign the URL (1 year expiry automatically handled by SupabaseUrlHelper)
      final signedUrl =
          await SupabaseUrlHelper().getFreshSignedUrl(bucketName, storagePath);

      // Step 2: Establish HTTP connection with chunked streaming
      final request = await HttpClient().getUrl(Uri.parse(signedUrl));
      final streamedResponse = await request.close();

      if (streamedResponse.statusCode != 200) {
        throw Exception('Download HTTP error: ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength;
      final localPath = await getLocalPath(fileName, userId: userId);
      final localFile = File(localPath);
      
      sink = localFile.openWrite();
      int received = 0;

      // Step 3: Stream and check for cancellation on every chunk
      await for (final chunk in streamedResponse) {
        if (cancelToken.isCancelled) {
          task.status = DownloadStatus.cancelled;
          await sink.close();
          await _cleanupPartialFile(fileName, userId);
          return;
        }

        sink.add(chunk);
        received += chunk.length;

        if (contentLength > 0) {
          final progress = received / contentLength;
          task.progress = progress;
          onProgress(progress);
        }
      }

      await sink.close();
      sink = null;

      // Step 4: Final verification
      if (cancelToken.isCancelled) {
        await _cleanupPartialFile(fileName, userId);
        return;
      }

      // Step 5: Update Manifest
      await _registerOwnership(userId, fileName);

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      onProgress(1.0);
      onComplete(localPath);
    } catch (e, stack) {
      task.status = DownloadStatus.error;
      if (sink != null) await sink.close();
      await _cleanupPartialFile(fileName, userId);
      CrashlyticsService.instance.recordError(e, stack,
          reason: 'Background download failed: $fileName');
      onError(e.toString());
    } finally {
      // Clean up task map after a short buffer
      await Future.delayed(const Duration(seconds: 2));
      _activeTasks.remove(taskId);
    }
  }

  // ── LEGACY & COMPATIBILITY LAYER ───────────────────────────────────────────

  /// Streams download progress for legacy UI components.
  Stream<DownloadProgress> downloadFileWithProgress(String url, String filename,
      {String? userId}) async* {
    if (userId == null || userId.isEmpty) {
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: 0,
        percentage: 0,
        status: DownloadStatus.error,
        errorMessage: 'Authentication required to download files',
      );
      return;
    }
    try {
      final path = await getLocalPath(filename, userId: userId);
      final file = File(path);
      if (await file.exists()) {
        await _registerOwnership(userId, filename);
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 100.0,
          status: DownloadStatus.completed,
        );
        return;
      }
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        yield DownloadProgress(
          bytesReceived: 0,
          totalBytes: 0,
          percentage: 0.0,
          status: DownloadStatus.error,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        return;
      }
      final contentLength = response.contentLength == -1 ? 0 : response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();
      await for (final chunk in response) {
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
      await _registerOwnership(userId, filename);
      yield DownloadProgress(
        bytesReceived: receivedBytes,
        totalBytes: contentLength,
        percentage: 100.0,
        status: DownloadStatus.completed,
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'download_service');
      yield DownloadProgress(
        bytesReceived: 0,
        totalBytes: 0,
        percentage: 0.0,
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Simple one-shot download for legacy callers.
  Future<String> downloadFile(String url, String filename,
      {Function(double)? onProgress, String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('userId is required to download files');
    }
    try {
      final path = await getLocalPath(filename, userId: userId);
      final file = File(path);
      if (await file.exists()) {
        await _registerOwnership(userId, filename);
        return path;
      }
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
      final contentLength = response.contentLength == -1 ? 0 : response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();
      await response.listen(
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
          throw e;
        },
        cancelOnError: true,
      ).asFuture();
      await _registerOwnership(userId, filename);
      return path;
    } catch (e) {
      rethrow;
    }
  }

  /// Clears all files in a user's sandbox. Used by DownloadsScreen.
  Future<void> clearAllDownloads(String userId) async {
    if (userId.isEmpty) return;
    try {
      final dir = await _userDir(userId);
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          await entity.delete(recursive: true);
        }
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'clearAllDownloads failed');
      rethrow;
    }
  }

  /// Deletes a specific test result record.
  Future<bool> deleteTestResult(int resultId, String userId) async {
    try {
      final existing = await Supabase.instance.client
          .from('results')
          .select('user_id')
          .eq('result_id', resultId)
          .maybeSingle();
      if (existing == null) return false;
      final response = await Supabase.instance.client
          .from('results')
          .delete()
          .eq('result_id', resultId)
          .select();
      return (response as List).isNotEmpty;
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'deleteTestResult failed');
      return false;
    }
  }

  Future<void> migrateOldDownloads(String userId) async {
    if (userId.isEmpty) return;
    try {
      final root = await getApplicationDocumentsDirectory();
      final userDir = await _userDir(userId);
      final pattern = RegExp(r'^(resource_\d+\.pdf|mock_test_\d+\.json)$');
      final entities = root.listSync();

      for (final entity in entities) {
        if (entity is! File) continue;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (!pattern.hasMatch(name)) continue;

        final dest = File('${userDir.path}/$name');
        if (!await dest.exists()) {
          await entity.copy(dest.path);
          await _registerOwnership(userId, name);
        }
        await entity.delete();
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Migration of old downloads failed');
    }
  }

  Future<bool> isFileDownloaded(String filename, {String? userId}) async {
    if (userId == null || userId.isEmpty) return false;
    try {
      final path = await getLocalPath(filename, userId: userId);
      return File(path).exists();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'download_service');
      return false;
    }
  }

  Future<void> deleteFile(String filename, {String? userId}) async {
    if (userId == null || userId.isEmpty) return;
    final path = await getLocalPath(filename, userId: userId);
    final file = File(path);
    if (await file.exists()) await file.delete();

    final manifest = await _readManifest(userId);
    manifest.remove(filename.replaceAll(RegExp(r'[^\w\s\.-]'), '_'));
    await _writeManifest(userId, manifest);
  }

  Future<int> getTotalStorageUsed(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final dir = await _userDir(userId);
      int total = 0;
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) total += await entity.length();
        }
      }
      return total;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'download_service');
      return 0;
    }
  }
}
