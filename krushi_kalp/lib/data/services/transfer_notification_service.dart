import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../utils/crashlytics_service.dart';

/// A unified service for managing local notifications related to file transfers
/// (both uploads and downloads).
class TransferNotificationService {
  static final TransferNotificationService _instance =
      TransferNotificationService._internal();
  factory TransferNotificationService() => _instance;
  TransferNotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;

  // Notification Channel IDs
  static const String _uploadChannelId = 'krushi_upload_progress';
  static const String _uploadChannelName = 'File Uploads';
  static const String _uploadChannelDesc =
      'Shows upload progress for admin file operations';

  static const String _downloadChannelId = 'krushi_download_progress';
  static const String _downloadChannelName = 'File Downloads';
  static const String _downloadChannelDesc =
      'Shows download progress for purchased content';

  /// Initializes the service with an existing [FlutterLocalNotificationsPlugin] instance.
  /// This ensures we don't double-initialize the platform-specific notification system.
  void initialize(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  /// Helper to generate a unique numeric ID for a task-based notification.
  int _notifId(String taskId) => taskId.hashCode.abs() % 10000;

  /// Sets up the necessary Android notification channels for transfers.
  /// Should be called during app initialization.
  Future<void> setupChannel() async {
    if (_plugin == null) return;

    // 1. Upload Channel
    const uploadChannel = AndroidNotificationChannel(
      _uploadChannelId,
      _uploadChannelName,
      description: _uploadChannelDesc,
      importance:
          Importance.low, // Use Low to avoid sound on every progress tick
      playSound: false,
      enableVibration: false,
    );

    // 2. Download Channel
    const downloadChannel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDesc,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(uploadChannel);
      await androidPlugin.createNotificationChannel(downloadChannel);
    }
  }

  // ── UPLOAD NOTIFICATIONS (ADMIN) ──────────────────────────────────────────

  /// Shows or updates an upload progress notification.
  Future<void> showUploadProgress({
    required String taskId,
    required String fileName,
    required double progress,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    final percent = (progress * 100).toInt();

    await _plugin!.show(
      id,
      'Uploading $fileName',
      '$percent% complete',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _uploadChannelId,
          _uploadChannelName,
          channelDescription: _uploadChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: percent,
          indeterminate: false,
          ongoing: true, // User cannot swipe away while uploading
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false, // Silent during progress on iOS
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Shows a success notification for an upload, replacing the progress bar.
  Future<void> showUploadSuccess({
    required String taskId,
    required String fileName,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id); // Cancel progress notification first

    await _plugin!.show(
      id,
      'Upload Complete ✓',
      '$fileName uploaded successfully',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _uploadChannelId,
          _uploadChannelName,
          channelDescription: _uploadChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Shows a failure notification for an upload.
  Future<void> showUploadFailure({
    required String taskId,
    required String fileName,
    required String error,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);

    await _plugin!.show(
      id,
      'Upload Failed ✗',
      '$fileName could not be uploaded. Tap to retry.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _uploadChannelId,
          _uploadChannelName,
          channelDescription: _uploadChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'upload_retry__$taskId',
    );
  }

  // ── DOWNLOAD NOTIFICATIONS (USER) ─────────────────────────────────────────

  /// Shows or updates a download progress notification.
  Future<void> showDownloadProgress({
    required String taskId,
    required String fileName,
    required double progress,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    final percent = (progress * 100).toInt();

    await _plugin!.show(
      id,
      'Downloading $fileName',
      '$percent% — Tap to open app',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: percent,
          indeterminate: false,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Shows a success notification for a download, replacing the progress bar.
  Future<void> showDownloadSuccess({
    required String taskId,
    required String fileName,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);

    await _plugin!.show(
      id,
      'Download Complete ✓',
      '$fileName is ready. Tap to start exam.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'download_complete__$taskId',
    );
  }

  /// Dismisses the progress notification silently when a download is cancelled.
  Future<void> showDownloadCancelled({
    required String taskId,
    required String fileName,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);
    // Log the cancellation safely
    CrashlyticsService.instance
        .log('Download notification cancelled for: $fileName (Task: $taskId)');
  }

  /// Shows a failure notification for a download.
  Future<void> showDownloadFailure({
    required String taskId,
    required String fileName,
    required String error,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);

    await _plugin!.show(
      id,
      'Download Failed ✗',
      '$fileName failed. Tap to retry.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: true,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: 'download_retry__$taskId',
    );
  }
}
