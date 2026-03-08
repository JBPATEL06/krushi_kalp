import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/transfer_notification_service.dart';
import '../../widgets/common/responsive_wrapper.dart';
import '../../../utils/crashlytics_service.dart';

/// A professional download button that handles background transfers,
/// progress notifications, and local file status automatically.
class DownloadActionButton extends StatefulWidget {
  final String filename;
  final String? url; // Storage path or signed URL
  final String bucketName;
  final String
      testId; // Unique ID for progress tracking (test_id or resource_id)
  final String
      startLabel; // Label when file is already downloaded (e.g., "Open")
  final Future<void> Function()
      onAction; // Callback after download is confirmed/opened
  final bool isFullWidth;
  final String? userId;
  final String? displayName; // Human-readable name (e.g., "gujcet") // CHANGED

  const DownloadActionButton({
    super.key,
    required this.filename,
    required this.url,
    this.bucketName = 'mock_test',
    required this.testId,
    this.startLabel = "Open",
    required this.onAction,
    this.isFullWidth = true,
    this.userId,
    this.displayName, // CHANGED
  });

  @override
  State<DownloadActionButton> createState() => _DownloadActionButtonState();
}

class _DownloadActionButtonState extends State<DownloadActionButton> {
  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _checking = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  /// Checks if the file exists locally to determine initial button state.
  Future<void> _checkStatus() async {
    if (!mounted) return;

    final currentUserId = widget.userId ?? AuthService.instance.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final exists = await DownloadService()
        .isFileDownloaded(widget.filename, userId: currentUserId);
    if (mounted) {
      setState(() {
        _isDownloaded = exists;
        _checking = false;
      });
    }
  }

  /// Initiates the background download process.
  Future<void> _handleDownload() async {
    final currentUserId = widget.userId ?? AuthService.instance.currentUser?.id;
    if (currentUserId == null || widget.url == null) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      await DownloadService().downloadFileInBackground(
        testId: widget.testId,
        fileName: widget.filename,
        storagePath: widget.url!,
        bucketName: widget.bucketName,
        userId: currentUserId,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
          // Update notification tray
          TransferNotificationService().showDownloadProgress(
            taskId: widget.testId,
            fileName: widget.displayName ?? widget.filename, // CHANGED
            progress: p,
          );
        },
        onComplete: (localPath) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isDownloaded = true;
              _progress = 1.0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${widget.displayName ?? widget.filename} downloaded successfully.')), // CHANGED
            );
          }
        },
        onError: (err) {
          if (mounted) setState(() => _isDownloading = false);
          TransferNotificationService().showDownloadFailure(
            taskId: widget.testId,
            fileName: widget.displayName ?? widget.filename, // CHANGED
            error: err,
          );
        },
      );
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'Manual download trigger failed');
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void didUpdateWidget(covariant DownloadActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filename != widget.filename ||
        oldWidget.testId != widget.testId) {
      _checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return SizedBox(
        height: context.h(48),
        child: const Center(
            child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // UI Logic for button states
    final String label = _isDownloading
        ? "${(_progress * 100).toInt()}%"
        : (_isDownloaded ? widget.startLabel : "Download Content");

    final IconData icon = _isDownloading
        ? Icons.sync_rounded
        : (_isDownloaded
            ? Icons.play_circle_outline_rounded
            : Icons.file_download_outlined);

    return Stack(
      // CHANGED (Wrapped in Stack)
      clipBehavior: Clip.none, // CHANGED
      children: [
        ElevatedButton.icon(
          onPressed: _isDownloading
              ? null
              : () async {
                  if (_isDownloaded) {
                    await widget.onAction();
                  } else {
                    await _handleDownload();
                  }
                },
          icon: _isDownloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(icon, color: Colors.white, size: context.sp(20)),
          label: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: context.sp(14),
              letterSpacing: 1.1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            disabledBackgroundColor: colorScheme.primary.withOpacity(0.6),
            padding: EdgeInsets.symmetric(
                vertical: context.h(12), horizontal: context.w(24)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            minimumSize:
                Size(widget.isFullWidth ? double.infinity : 0, context.h(48)),
          ),
        ),
        if (_isDownloading) // CHANGED (Positioned at bottom of button)
          Positioned(
            bottom: 0,
            left: 12,
            right: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}
