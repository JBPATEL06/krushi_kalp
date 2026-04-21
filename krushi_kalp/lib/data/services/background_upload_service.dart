import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/retry_helper.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../core/env/env.dart';
import 'package:flutter/material.dart' show debugPrint;

/// Status of an upload task managed by [BackgroundUploadService].
enum UploadTaskStatus { pending, uploading, completed, failed }

/// Model representing a single file upload task.
class UploadTask {
  final String taskId;
  final String fileName;
  final String itemName;
  final String bucketName;
  final String storagePath;
  final String? filePath;
  final String fileType;
  UploadTaskStatus status;
  double progress;
  String? errorMessage;
  String? completedPath;

  UploadTask({
    required this.taskId,
    required this.fileName,
    required this.itemName,
    required this.bucketName,
    required this.storagePath,
    this.filePath,
    required this.fileType,
    this.status = UploadTaskStatus.uploading,
    this.progress = 0.0,
    this.errorMessage,
    this.completedPath,
  });
}

/// A singleton service that handles file uploads to Supabase Storage in the background.
/// This service allows the UI to fire-and-forget uploads while still receiving
/// progress, completion, and error updates.
class BackgroundUploadService {
  static final BackgroundUploadService _instance =
      BackgroundUploadService._internal();
  factory BackgroundUploadService() => _instance;

  BackgroundUploadService._internal() {
    _setupIsolateListeners();
  }
  
  /// Listen for events coming back from the background isolate and route them to UI callbacks.
  void _setupIsolateListeners() {
    if (kIsWeb) return;

    final service = FlutterBackgroundService();
    
    service.on('uploadProgress').listen((event) {
      if (event == null) return;
      final taskId = event['taskId'] as String;
      final progress = event['progress'] as double;
      
      final task = _activeTasks[taskId];
      if (task != null) {
        task.progress = progress;
        _taskCallbacks[taskId]?['onProgress']?.call(progress);
      }
    });

    service.on('uploadComplete').listen((event) {
      if (event == null) return;
      final taskId = event['taskId'] as String;
      final path = event['path'] as String;
      
      final task = _activeTasks[taskId];
      if (task != null) {
        task.status = UploadTaskStatus.completed;
        task.completedPath = path;
        _taskCallbacks[taskId]?['onComplete']?.call(path);
        _cleanupTask(taskId);
      }
    });

    service.on('uploadError').listen((event) {
      if (event == null) return;
      final taskId = event['taskId'] as String;
      final error = event['error'] as String;
      
      final task = _activeTasks[taskId];
      if (task != null) {
        task.status = UploadTaskStatus.failed;
        task.errorMessage = error;
        _taskCallbacks[taskId]?['onError']?.call(error);
        _cleanupTask(taskId);
      }
    });
  }

  /// Map of currently active upload tasks keyed by [taskId].
  final Map<String, UploadTask> _activeTasks = {};
  
  /// Registry of callbacks for active tasks.
  final Map<String, Map<String, Function>> _taskCallbacks = {};

  Timer? _idleTimer;

  void _cleanupTask(String taskId) {
    // Keep task in activeTasks briefly for UI to see final state
    Future.delayed(const Duration(seconds: 5), () {
      _activeTasks.remove(taskId);
      _taskCallbacks.remove(taskId);
      
      // If no more tasks, start idle watchdog
      if (_activeTasks.isEmpty) {
        _startIdleWatchdog();
      }
    });
  }

  void _startIdleWatchdog() {
    _idleTimer?.cancel();
    // 30 second idle window before complete shutdown to prevent 
    // ForegroundServiceDidNotStopInTimeException on Android 14
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (_activeTasks.isEmpty) {
        debugPrint('BackgroundUploadService: Idle timeout reached. Stopping service.');
        FlutterBackgroundService().invoke('setAsBackground');
        // Proactively stop the service entirely if idle
        FlutterBackgroundService().invoke('stopService');
      }
    });
  }

  void _cancelIdleWatchdog() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Returns an unmodifiable map of all currently active upload tasks.
  Map<String, UploadTask> get activeTasks => Map.unmodifiable(_activeTasks);

  /// Starts a new file upload task. Returns the [taskId] immediately.
  ///
  /// The upload runs as a background future. Callers should provide callbacks
  /// for progress, completion, and error handling.
  Future<String> uploadFile({
    required String fileName,
    required String itemName,
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
    _cancelIdleWatchdog();
    final id = taskId ?? const Uuid().v4();
    final sanitizedPath = _sanitizePath(storagePath);

    String? finalFilePath = filePath;

    // If we have bytes but no file path, write to a temp file first.
    // Standard isolate message passing has limits, and Supabase storage
    // works better with physical files in the background worker.
    if (fileBytes != null && finalFilePath == null) {
      try {
        final tempDir = await _getTempDir();
        final tempFile = File('${tempDir.path}/upload_$id');
        await tempFile.writeAsBytes(fileBytes);
        finalFilePath = tempFile.path;
      } catch (e) {
        onError('Failed to create temporary file for upload: $e');
        return id;
      }
    }

    final task = UploadTask(
      taskId: id,
      fileName: fileName,
      itemName: itemName,
      bucketName: bucketName,
      storagePath: sanitizedPath,
      filePath: finalFilePath,
      fileType: fileType,
      status: UploadTaskStatus.uploading,
    );
    _activeTasks[id] = task;
    _taskCallbacks[id] = {
      'onProgress': onProgress,
      'onComplete': onComplete,
      'onError': onError,
    };
    
    // Ensure the foreground service is running
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      service.invoke('setAsForeground');
      
      // Handoff to background isolate
      service.invoke('startUpload', {
        'taskId': id,
        'fileName': fileName,
        'itemName': itemName,
        'bucketName': bucketName,
        'storagePath': sanitizedPath,
        'filePath': finalFilePath,
        'fileType': fileType,
      });

    } catch (e) {
      CrashlyticsService.instance.log('Background upload start failed: $e');
      onError(e.toString());
    }

    return id;
  }

  Future<Directory> _getTempDir() async {
    // We use path_provider indirectly if possible, but since this is a service
    // we might need to import it.
    // For now, let's assume we can use standard temp dir or pass it in.
    return Directory.systemTemp;
  }


  /// (Isolate-side) Performs the actual Supabase upload within the background isolate.
  /// This must be static or a top-level function so it can be called safely in the isolate.
  static Future<void> performUploadTask(ServiceInstance service, Map<String, dynamic> data) async {
    final taskId = data['taskId'] as String;
    final fileName = data['fileName'] as String;
    final itemName = data['itemName'] as String;
    final bucketName = data['bucketName'] as String;
    final storagePath = data['storagePath'] as String;
    final filePath = data['filePath'] as String?;
    
    // 1. Ensure Supabase is initialized in THIS isolate
    if (!isSupabaseInitialized()) {
      try {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          anonKey: Env.supabaseAnonKey,
        );
      } catch (e) {
        debugPrint('Background Isolate Supabase init failed: $e');
      }
    }

    Timer? progressTimer;
    double progress = 0.05;

    try {
      // 2. Start progress simulation
      progressTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (progress < 0.95) {
          final remaining = 1.0 - progress;
          progress += remaining * 0.05;
          final percent = (progress * 100).toInt();
          
          service.invoke('updateProgress', {
            'title': 'Uploading $itemName',
            'content': '$percent% complete',
          });
          
          // Send raw progress back to UI isolate if it's listening
          service.invoke('uploadProgress', {
            'taskId': taskId,
            'progress': progress,
          });
        }
      });

      // 3. Perform upload with retries
      await RetryHelper.run(
        () async {
          final contentType = _getContentTypeStatic(storagePath);

          if (filePath != null) {
            await Supabase.instance.client.storage
                .from(bucketName)
                .upload(
                  storagePath,
                  File(filePath),
                  fileOptions: FileOptions(upsert: true, contentType: contentType),
                );
          } else {
             throw Exception('No file path provided in background worker');
          }
        },
        maxRetries: 8,
        initialDelay: const Duration(seconds: 5),
        timeout: const Duration(seconds: 300),
      );

      // 4. Cleanup and success
      progressTimer.cancel();
      service.invoke('clearProgress', {
        'content': '✓ $itemName uploaded successfully',
      });
      service.invoke('uploadComplete', {
        'taskId': taskId,
        'path': storagePath,
      });

    } catch (e, stack) {
      progressTimer?.cancel();
      CrashlyticsService.instance.recordError(e, stack, reason: 'Background isolate upload crashed: $itemName ($fileName)');
      
      service.invoke('clearProgress', {
        'content': '✗ $itemName upload failed – check your connection',
      });
      service.invoke('uploadError', {
        'taskId': taskId,
        'error': e.toString(),
      });
    } finally {
      progressTimer?.cancel();
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

  /// Static version for isolate usage
  static String _getContentTypeStatic(String path) {
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

/// Helper to check if Supabase is initialized in the current isolate.
bool isSupabaseInitialized() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}
