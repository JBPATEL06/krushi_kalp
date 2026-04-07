import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/retry_helper.dart';

/// Status of an upload task managed by [BackgroundUploadService].
enum UploadTaskStatus { pending, uploading, completed, failed }

/// Model representing a single file upload task.
class UploadTask {
  final String taskId;
  final String fileName;
  final String bucketName;
  final String storagePath;
  final Uint8List fileBytes;
  final String fileType; // 'resource_pdf', 'resource_cover', 'mock_test_excel'
  UploadTaskStatus status;
  double progress; // 0.0 to 1.0
  String? errorMessage;
  String? completedPath; // storage path returned after success

  UploadTask({
    required this.taskId,
    required this.fileName,
    required this.bucketName,
    required this.storagePath,
    required this.fileBytes,
    required this.fileType,
    this.status = UploadTaskStatus.pending,
    this.progress = 0.0,
  });
}

/// A singleton service that handles file uploads to Supabase Storage in the background.
/// This service allows the UI to fire-and-forget uploads while still receiving
/// progress, completion, and error updates.
class BackgroundUploadService {
  static final BackgroundUploadService _instance =
      BackgroundUploadService._internal();
  factory BackgroundUploadService() => _instance;
  BackgroundUploadService._internal();

  /// Map of currently active upload tasks keyed by [taskId].
  final Map<String, UploadTask> _activeTasks = {};

  /// Returns an unmodifiable map of all currently active upload tasks.
  Map<String, UploadTask> get activeTasks => Map.unmodifiable(_activeTasks);

  /// Starts a new file upload task. Returns the [taskId] immediately.
  ///
  /// The upload runs as a background future. Callers should provide callbacks
  /// for progress, completion, and error handling.
  Future<String> uploadFile({
    required String fileName,
    required String bucketName,
    required String storagePath,
    required Uint8List fileBytes,
    required String fileType,
    required Function(double progress) onProgress,
    required Function(String path) onComplete,
    required Function(String error) onError,
    String? taskId,
  }) async {
    final id = taskId ?? const Uuid().v4();
    final sanitizedPath = _sanitizePath(storagePath);

    final task = UploadTask(
      taskId: id,
      fileName: fileName,
      bucketName: bucketName,
      storagePath: sanitizedPath,
      fileBytes: fileBytes,
      fileType: fileType,
      status: UploadTaskStatus.uploading,
    );
    _activeTasks[id] = task;

    // Start the upload process without awaiting it to return the taskId immediately.
    _executeUpload(task, onProgress, onComplete, onError);

    return id;
  }

  /// Internal method that executes the actual Supabase upload with retries and progress simulation.
  Future<void> _executeUpload(
    UploadTask task,
    Function(double progress) onProgress,
    Function(String path) onComplete,
    Function(String error) onError,
  ) async {
    try {
      // Supabase's current uploadBinary is atomic and doesn't provide native chunked progress.
      // We simulate progress ticks to give visual feedback until the atomic operation finishes.
      task.progress = 0.1;
      onProgress(0.1);

      // Use RetryHelper to handle transient network issues (max 3 attempts).
      await RetryHelper.run(
        () async {
          // Increment simulated progress during wait/retry phases
          if (task.progress < 0.6) {
            task.progress += 0.2;
            onProgress(task.progress);
          }

          final contentType = _getContentType(task.storagePath);

          await Supabase.instance.client.storage
              .from(task.bucketName)
              .uploadBinary(
                task.storagePath,
                task.fileBytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: contentType,
                ),
              );
        },
        maxRetries: 8,
        initialDelay: const Duration(seconds: 5),
        maxDelay: const Duration(minutes: 2),
        timeout: const Duration(seconds: 180),
      );

      // Mark task as completed
      task.progress = 1.0;
      task.status = UploadTaskStatus.completed;
      task.completedPath = task.storagePath;

      onProgress(1.0);
      onComplete(task.storagePath);
    } catch (e, stack) {
      task.status = UploadTaskStatus.failed;
      task.errorMessage = e.toString();

      // Log the failure to Crashlytics
      CrashlyticsService.instance.recordError(e, stack,
          reason:
              'Background upload failed: ${task.fileName} in ${task.bucketName} (Path: ${task.storagePath})');

      onError(e.toString());
    } finally {
      // Retain the task in active tasks for a short duration (3s)
      // so UI or notification service can process the final state.
      await Future.delayed(const Duration(seconds: 3));
      _activeTasks.remove(task.taskId);
    }
  }

  /// Sanitizes the storage path by ensuring the filename segment contains no illegal characters.
  String _sanitizePath(String path) {
    if (path.isEmpty) return path;

    final segments = path.split('/');
    final fileName = segments.last;

    // Replace all non-alphanumeric (excluding . and -) with underscores.
    // This handles spaces, non-breaking spaces, and other symbols that break URLs.
    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');

    segments[segments.length - 1] = sanitizedName;
    return segments.join('/');
  }

  /// Returns the MIME type based on file extension.
  String _getContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'json':
        return 'application/json';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
