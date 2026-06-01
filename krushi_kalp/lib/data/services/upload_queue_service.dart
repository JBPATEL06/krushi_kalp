import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'background_upload_service.dart';

/// A single upload request to be placed in the FIFO queue.
class QueuedUploadRequest {
  final String taskId;
  final String fileName;
  final String itemName;
  final String bucketName;
  final String storagePath;
  final Uint8List? fileBytes;
  final String? filePath;
  final String fileType;
  final Map<String, dynamic>? dbUpdate;
  final Function(double progress) onProgress;
  final Function(String path) onComplete;
  final Function(String error) onError;

  const QueuedUploadRequest({
    required this.taskId,
    required this.fileName,
    required this.itemName,
    required this.bucketName,
    required this.storagePath,
    this.fileBytes,
    this.filePath,
    required this.fileType,
    this.dbUpdate,
    required this.onProgress,
    required this.onComplete,
    required this.onError,
  });
}

/// Status of the upload queue.
enum QueueStatus { idle, processing }

/// Snapshot of the upload queue state for UI consumption.
class UploadQueueSnapshot {
  final QueueStatus status;
  final String? activeTaskId;
  final String? activeItemName;
  final double activeProgress;
  final List<String> pendingTaskIds;
  final int pendingCount;

  const UploadQueueSnapshot({
    required this.status,
    this.activeTaskId,
    this.activeItemName,
    required this.activeProgress,
    required this.pendingTaskIds,
    required this.pendingCount,
  });

  bool get isIdle => status == QueueStatus.idle;
  bool get isProcessing => status == QueueStatus.processing;
}

/// A singleton FIFO queue that serializes all file uploads through
/// [BackgroundUploadService]. Only one upload runs at a time.
///
/// **Usage rule (Anti-Gravity Law §FIFO):**
/// ALL upload calls must go through `UploadQueueService().enqueue(...)`.
/// Never call `BackgroundUploadService().uploadFile(...)` directly from UI.
class UploadQueueService {
  static final UploadQueueService _instance = UploadQueueService._internal();
  factory UploadQueueService() => _instance;
  UploadQueueService._internal();

  // ── Internal State ──────────────────────────────────────────────────────

  final Queue<QueuedUploadRequest> _queue = Queue<QueuedUploadRequest>();
  bool _isProcessing = false;
  QueuedUploadRequest? _activeRequest;
  double _activeProgress = 0.0;

  // ── State Stream ─────────────────────────────────────────────────────────

  final StreamController<UploadQueueSnapshot> _snapshotController =
      StreamController<UploadQueueSnapshot>.broadcast();

  /// Stream of queue state changes. Subscribe in UI to show upload progress.
  Stream<UploadQueueSnapshot> get onQueueChanged => _snapshotController.stream;

  /// Current snapshot without subscribing to stream.
  UploadQueueSnapshot get currentSnapshot => UploadQueueSnapshot(
        status: _isProcessing ? QueueStatus.processing : QueueStatus.idle,
        activeTaskId: _activeRequest?.taskId,
        activeItemName: _activeRequest?.itemName,
        activeProgress: _activeProgress,
        pendingTaskIds: _queue.map((r) => r.taskId).toList(),
        pendingCount: _queue.length,
      );

  void _emitSnapshot() {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(currentSnapshot);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Enqueues a file upload. Returns immediately — upload runs in background
  /// after all previously enqueued uploads complete (FIFO order).
  void enqueue(QueuedUploadRequest request) {
    // Prevent duplicate task IDs in queue
    final alreadyQueued =
        _queue.any((r) => r.taskId == request.taskId) ||
            _activeRequest?.taskId == request.taskId;
    if (alreadyQueued) {
      debugPrint(
          'UploadQueueService: Task ${request.taskId} is already queued or active. Skipping.');
      return;
    }

    _queue.addLast(request);
    debugPrint(
        'UploadQueueService: Enqueued "${request.itemName}" (${request.taskId}). Queue length: ${_queue.length}');
    _emitSnapshot();

    if (!_isProcessing) {
      _processNext();
    }
  }

  /// Returns true if a task with the given [taskId] is queued or currently active.
  bool isQueued(String taskId) {
    return _activeRequest?.taskId == taskId ||
        _queue.any((r) => r.taskId == taskId);
  }

  /// Cancels a pending (not yet started) upload from the queue.
  /// Cannot cancel an already-active upload.
  bool cancelPending(String taskId) {
    final before = _queue.length;
    _queue.removeWhere((r) => r.taskId == taskId);
    final removed = _queue.length < before;
    if (removed) {
      debugPrint('UploadQueueService: Cancelled pending task $taskId');
      _emitSnapshot();
    }
    return removed;
  }

  // ── Internal Processing ───────────────────────────────────────────────────

  Future<void> _processNext() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      _activeRequest = null;
      _activeProgress = 0.0;
      debugPrint('UploadQueueService: Queue empty. Going idle.');
      _emitSnapshot();
      return;
    }

    _isProcessing = true;
    final request = _queue.removeFirst();
    _activeRequest = request;
    _activeProgress = 0.0;
    _emitSnapshot();

    debugPrint(
        'UploadQueueService: Starting upload "${request.itemName}" (${request.taskId})');

    // Use a Completer to await BackgroundUploadService's callback-based API
    final completer = Completer<void>();

    await BackgroundUploadService().uploadFile(
      taskId: request.taskId,
      fileName: request.fileName,
      itemName: request.itemName,
      bucketName: request.bucketName,
      storagePath: request.storagePath,
      fileBytes: request.fileBytes,
      filePath: request.filePath,
      fileType: request.fileType,
      dbUpdate: request.dbUpdate,
      onProgress: (progress) {
        _activeProgress = progress;
        _emitSnapshot();
        request.onProgress(progress);
      },
      onComplete: (path) {
        debugPrint(
            'UploadQueueService: Completed "${request.itemName}" → $path');
        request.onComplete(path);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (error) {
        debugPrint(
            'UploadQueueService: Failed "${request.itemName}": $error');
        request.onError(error);
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Wait for upload to finish before starting next
    await completer.future;

    // Process the next item
    _processNext();
  }

  /// Disposes the stream controller. Call only on app shutdown.
  void dispose() {
    _snapshotController.close();
  }
}


