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

  static const String _serviceChannelId = 'krushi_background_service';
  static const String _serviceChannelName = 'Background Services';
  static const String _serviceChannelDesc =
      'Keeps the app running for long transfers';

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
      importance: Importance.high, // Increased to High for MIUI visibility
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // 2. Download Channel
    const downloadChannel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDesc,
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // 3. Service Channel (For foreground service itself)
    const serviceChannel = AndroidNotificationChannel(
      _serviceChannelId,
      _serviceChannelName,
      description: _serviceChannelDesc,
      importance: Importance.high, // Increased to high for visibility
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(uploadChannel);
      await androidPlugin.createNotificationChannel(downloadChannel);
      await androidPlugin.createNotificationChannel(serviceChannel);
    }
  }

  // ── UPLOAD NOTIFICATIONS (ADMIN) ──────────────────────────────────────────

  /// Shows or updates an upload progress notification.
  Future<void> showUploadProgress({
    required String taskId,
    required String fileName,
    required double progress,
  }) async {
    // Disabled as requested
    return;
  }

  /// Shows a success notification for an upload, replacing the progress bar.
  Future<void> showUploadSuccess({
    required String taskId,
    required String fileName,
  }) async {
    // Disabled as requested
    return;
  }

  /// Shows a failure notification for an upload.
  Future<void> showUploadFailure({
    required String taskId,
    required String fileName,
    required String error,
  }) async {
    // Disabled as requested
    return;
  }

  // ── DOWNLOAD NOTIFICATIONS (USER) ─────────────────────────────────────────

  /// Shows or updates a download progress notification.
  Future<void> showDownloadProgress({
    required String taskId,
    required String itemName,
    required double progress,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    final percent = (progress * 100).toInt();

    await _plugin!.show(
      id,
      'Downloading $itemName',
      '$percent% — Tap to open app',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          showProgress: true,
          maxProgress: 100,
          progress: percent,
          indeterminate: false,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: true,
          playSound: false,
          enableVibration: false,
          icon: 'ic_notification',
          ticker: 'Downloading $itemName...',
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
    required String itemName,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);

    await _plugin!.show(
      id,
      'Download Complete ✓',
      '$itemName is ready. Tap to start exam.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          autoCancel: true,
          icon: 'ic_notification',
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
    required String itemName,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);
    // Log the cancellation safely
    CrashlyticsService.instance
        .log('Download notification cancelled for: $itemName (Task: $taskId)');
  }

  /// Shows a failure notification for a download.
  Future<void> showDownloadFailure({
    required String taskId,
    required String itemName,
    required String error,
  }) async {
    if (_plugin == null) return;
    final id = _notifId(taskId);
    await _plugin!.cancel(id);

    await _plugin!.show(
      id,
      'Download Failed ✗',
      '$itemName failed. Tap to retry.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _downloadChannelId,
          _downloadChannelName,
          channelDescription: _downloadChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: false,
          autoCancel: true,
          icon: 'ic_notification',
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
