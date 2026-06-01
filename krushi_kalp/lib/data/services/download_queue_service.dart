import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart' show debugPrint;
import 'download_service.dart';
import '../../utils/crashlytics_service.dart';

/// A single download request to be placed in the FIFO queue.
class QueuedDownloadRequest {
  final String taskId;
  final String testId;
  final String fileName;
  final String itemName;
  final String storagePath;
  final String bucketName;
  final String userId;
  final DateTime? updatedAt;
  final Function(double progress) onProgress;
  final Function(String localPath) onComplete;
  final Function(String error) onError;

  const QueuedDownloadRequest({
    required this.taskId,
    required this.testId,
    required this.fileName,
    required this.itemName,
    required this.storagePath,
    required this.bucketName,
    required this.userId,
    this.updatedAt,
    required this.onProgress,
    required this.onComplete,
    required this.onError,
  });
}

/// Status of the download queue.
enum DownloadQueueStatus { idle, processing }

/// Snapshot of the download queue state for UI consumption.
class DownloadQueueSnapshot {
  final DownloadQueueStatus status;
  final String? activeTaskId;
  final String? activeItemName;
  final double activeProgress;
  final List<String> pendingTaskIds;
  final int pendingCount;

  const DownloadQueueSnapshot({
    required this.status,
    this.activeTaskId,
    this.activeItemName,
    required this.activeProgress,
    required this.pendingTaskIds,
    required this.pendingCount,
  });

  bool get isIdle => status == DownloadQueueStatus.idle;
  bool get isProcessing => status == DownloadQueueStatus.processing;
}

/// A singleton FIFO queue that serializes all file downloads through
/// [DownloadService]. Only one download runs at a time.
///
/// **Usage rule (Anti-Gravity Law §FIFO):**
/// ALL download calls must go through `DownloadQueueService().enqueue(...)`.
/// Never call `DownloadService().downloadFileInBackground(...)` directly from UI.
class DownloadQueueService {
  static final DownloadQueueService _instance =
      DownloadQueueService._internal();
  factory DownloadQueueService() => _instance;
  DownloadQueueService._internal();

  // ── Internal State ──────────────────────────────────────────────────────

  final Queue<QueuedDownloadRequest> _queue =
      Queue<QueuedDownloadRequest>();
  bool _isProcessing = false;
  QueuedDownloadRequest? _activeRequest;
  double _activeProgress = 0.0;

  // ── State Stream ─────────────────────────────────────────────────────────

  final StreamController<DownloadQueueSnapshot> _snapshotController =
      StreamController<DownloadQueueSnapshot>.broadcast();

  /// Stream of queue state changes. Subscribe in UI to show download queue status.
  Stream<DownloadQueueSnapshot> get onQueueChanged =>
      _snapshotController.stream;

  /// Current snapshot without subscribing to stream.
  DownloadQueueSnapshot get currentSnapshot => DownloadQueueSnapshot(
        status:
            _isProcessing ? DownloadQueueStatus.processing : DownloadQueueStatus.idle,
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

  /// Returns true if a task with the given [taskId] is queued or currently downloading.
  bool isQueued(String taskId) {
    return _activeRequest?.taskId == taskId ||
        _queue.any((r) => r.taskId == taskId);
  }

  /// Returns the position of a task in the queue (1-based), or 0 if active, -1 if not queued.
  int queuePosition(String taskId) {
    if (_activeRequest?.taskId == taskId) return 0;
    int pos = 1;
    for (final req in _queue) {
      if (req.taskId == taskId) return pos;
      pos++;
    }
    return -1;
  }

  /// Enqueues a file download. Returns immediately — download runs in background
  /// after all previously enqueued downloads complete (FIFO order).
  void enqueue(QueuedDownloadRequest request) {
    // Prevent duplicate task IDs
    final alreadyQueued =
        _queue.any((r) => r.taskId == request.taskId) ||
            _activeRequest?.taskId == request.taskId;
    if (alreadyQueued) {
      debugPrint(
          'DownloadQueueService: Task ${request.taskId} is already queued or active. Skipping.');
      return;
    }

    _queue.addLast(request);
    debugPrint(
        'DownloadQueueService: Enqueued "${request.itemName}" (${request.taskId}). Queue length: ${_queue.length}');
    _emitSnapshot();

    if (!_isProcessing) {
      _processNext();
    }
  }

  /// Cancels a pending (not yet started) download from the queue.
  /// Cannot cancel an already-active download.
  bool cancelPending(String taskId) {
    final before = _queue.length;
    _queue.removeWhere((r) => r.taskId == taskId);
    final removed = _queue.length < before;
    if (removed) {
      debugPrint('DownloadQueueService: Cancelled pending task $taskId');
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
      debugPrint('DownloadQueueService: Queue empty. Going idle.');
      _emitSnapshot();
      return;
    }

    _isProcessing = true;
    final request = _queue.removeFirst();
    _activeRequest = request;
    _activeProgress = 0.0;
    _emitSnapshot();

    debugPrint(
        'DownloadQueueService: Starting download "${request.itemName}" (${request.taskId})');

    // Use a Completer to await DownloadService's callback-based API
    final completer = Completer<void>();

    try {
      await DownloadService().downloadFileInBackground(
        testId: request.testId,
        fileName: request.fileName,
        itemName: request.itemName,
        storagePath: request.storagePath,
        bucketName: request.bucketName,
        userId: request.userId,
        updatedAt: request.updatedAt,
        onProgress: (progress) {
          _activeProgress = progress;
          _emitSnapshot();
          request.onProgress(progress);
        },
        onComplete: (localPath) {
          debugPrint(
              'DownloadQueueService: Completed "${request.itemName}" → $localPath');
          request.onComplete(localPath);
          if (!completer.isCompleted) completer.complete();
        },
        onError: (error) {
          debugPrint(
              'DownloadQueueService: Failed "${request.itemName}": $error');
          CrashlyticsService.instance.recordError(
            Exception(error),
            StackTrace.current,
            reason: 'DownloadQueueService failed to download ${request.itemName}: $error',
          );
          request.onError(error);
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e, stack) {
      debugPrint('DownloadQueueService: Unexpected exception: $e');
      CrashlyticsService.instance.recordError(
        e,
        stack,
        reason: 'DownloadQueueService unexpected loop crash for ${request.itemName}',
      );
      request.onError(e.toString());
      if (!completer.isCompleted) completer.complete();
    }

    // Wait for download to finish before starting next
    await completer.future;

    // Process the next item
    _processNext();
  }

  /// Disposes the stream controller. Call only on app shutdown.
  void dispose() {
    _snapshotController.close();
  }
}
