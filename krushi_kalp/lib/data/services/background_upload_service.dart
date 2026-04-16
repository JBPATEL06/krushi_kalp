import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/retry_helper.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../utils/network_utils.dart';

/// Status of an upload task managed by [BackgroundUploadService].
enum UploadTaskStatus { pending, uploading, completed, failed }

/// Model representing a single file upload task.
class UploadTask {
  final String taskId;
  final String fileName;
  final String bucketName;
  final String storagePath;
  final Uint8List? fileBytes;
  final String? filePath;
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
    this.fileBytes,
    this.filePath,
    required this.fileType,
    this.status = UploadTaskStatus.pending,
    this.progress = 0.0,
  }) : assert(fileBytes != null || filePath != null, 'Either fileBytes or filePath must be provided');
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
    Uint8List? fileBytes,
    String? filePath,
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
      filePath: filePath,
      fileType: fileType,
      status: UploadTaskStatus.uploading,
    );
    _activeTasks[id] = task;
    
    // Ensure the foreground service is running and in FOREGROUND mode
    // so the notification is visible during the upload.
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        // Give the service isolate time to initialise its event listeners
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // Always promote to foreground at upload start (handles the case where
      // the service was previously demoted to background after a previous upload)
      service.invoke('setAsForeground');
      await Future.delayed(const Duration(milliseconds: 100));
      // Show the initial "Uploading" notification immediately
      service.invoke('updateProgress', {
        'title': 'Uploading File: ${task.fileName}',
        'content': '0% complete',
      });
    } catch (e) {
      CrashlyticsService.instance.log('Foreground service start failed: $e');
    }

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
    // Timer to simulate progress breathing during long atomic operations
    Timer? progressTimer;
    try {
      task.progress = 0.05;
      onProgress(0.05);

      // Start "Asymptotic Progress" timer.
      // Moves quickly at first, then slows down as it approaches 0.99.
      // Drives the foreground service notification (ID 888) — the ONLY
      // notification MIUI guarantees stays visible.
      progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (task.status == UploadTaskStatus.uploading && task.progress < 0.95) {
          // Asymptotic increment: 5% of remaining distance each tick
          final remaining = 1.0 - task.progress;
          task.progress += remaining * 0.05;
          onProgress(task.progress);

          final percent = (task.progress * 100).toInt();
          // Drive the foreground service notification (always visible on MIUI)
          FlutterBackgroundService().invoke('updateProgress', {
            'title': 'Uploading File: ${task.fileName}',
            'content': '$percent% complete',
          });
        }
      });

      // Use RetryHelper to handle transient network issues (max 8 attempts).
      await RetryHelper.run(
        () async {
          final contentType = _getContentType(task.storagePath);

          if (!kIsWeb && task.filePath != null) {
            // Memory efficient: upload directly from disk file
            await Supabase.instance.client.storage
                .from(task.bucketName)
                .upload(
                  task.storagePath,
                  File(task.filePath!),
                  fileOptions: FileOptions(
                    upsert: true,
                    contentType: contentType,
                  ),
                );
          } else if (task.fileBytes != null) {
            // Upload from memory bytes
            await Supabase.instance.client.storage
                .from(task.bucketName)
                .uploadBinary(
                  task.storagePath,
                  task.fileBytes!,
                  fileOptions: FileOptions(
                    upsert: true,
                    contentType: contentType,
                  ),
                );
          } else {
            throw Exception('No file data or path available for upload');
          }
        },
        maxRetries: 8,
        initialDelay: const Duration(seconds: 5),
        maxDelay: const Duration(minutes: 2),
        timeout: const Duration(seconds: 300), // 5 min timeout for large files
      );

      // Mark task as completed
      progressTimer.cancel();
      task.progress = 1.0;
      task.status = UploadTaskStatus.completed;
      task.completedPath = task.storagePath;

      onProgress(1.0);
      // Update foreground notification to success state
      FlutterBackgroundService().invoke('clearProgress', {
        'content': '✓ ${task.fileName} uploaded successfully',
      });
      onComplete(task.storagePath);
    } catch (e, stack) {
      progressTimer?.cancel();
      task.status = UploadTaskStatus.failed;

      String userMessage = e.toString();
      if (NetworkUtils.isNetworkError(e)) {
        userMessage = 'Upload failed due to connection issues. Please check your internet and retry.';
      }
      task.errorMessage = userMessage;

      CrashlyticsService.instance.recordError(e, stack,
          reason:
              'Background upload failed: ${task.fileName} in ${task.bucketName} (Path: ${task.storagePath})');

      // Update foreground notification to failure state
      FlutterBackgroundService().invoke('clearProgress', {
        'content': '✗ ${task.fileName} upload failed – check your connection',
      });

      onError(e.toString());
    } finally {
      progressTimer?.cancel();
      // Retain the task in active tasks for a short duration (3s)
      // so UI or notification service can process the final state.
      await Future.delayed(const Duration(seconds: 3));
      _activeTasks.remove(task.taskId);

      // If no more active tasks, demote the service to background mode
      // (invisible — no notification) instead of killing it.
      // Killing and restarting causes MIUI to show the notification only once
      // because each new foreground service start is treated as a brand-new
      // notification by the OS and MIUI suppresses duplicates aggressively.
      if (_activeTasks.isEmpty) {
        try {
          FlutterBackgroundService().invoke('clearProgress', {
            'content': 'Transfer complete',
          });
          // Small delay to let the notification update settle, then demote
          await Future.delayed(const Duration(seconds: 2));
          FlutterBackgroundService().invoke('setAsBackground');
        } catch (_) {}
      }
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
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }
}
