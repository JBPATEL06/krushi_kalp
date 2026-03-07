import 'package:flutter/material.dart';
import '../../../data/services/download_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

/// A dialog that shows download progress with animated progress bar
class DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String filename;
  final String displayName;
  final Function(String path) onComplete;
  final VoidCallback? onError;

  const DownloadProgressDialog({
    super.key,
    required this.url,
    required this.filename,
    required this.displayName,
    required this.onComplete,
    this.onError,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  DownloadStatus _status = DownloadStatus.idle;
  String? _errorMessage;
  int _bytesReceived = 0;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    setState(() => _status = DownloadStatus.downloading);

    try {
      final stream = DownloadService()
          .downloadFileWithProgress(widget.url, widget.filename);

      await for (final progress in stream) {
        if (!mounted) return;

        setState(() {
          _progress = progress.percentage;
          _status = progress.status;
          _bytesReceived = progress.bytesReceived;
          _totalBytes = progress.totalBytes;
          _errorMessage = progress.errorMessage;
        });

        if (progress.isComplete) {
          // Show success state for 2 seconds before auto-closing
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            final path = await DownloadService().getLocalPath(widget.filename);
            Navigator.of(context).pop();
            widget.onComplete(path);
          }
          return;
        }

        if (progress.hasError) {
          if (mounted) {
            widget.onError?.call();
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = DownloadStatus.error;
          _errorMessage = e.toString();
        });
        widget.onError?.call();
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _status != DownloadStatus.downloading,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon/Status Indicator
              if (_status == DownloadStatus.downloading) ...[
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  strokeWidth: 3,
                ),
              ] else if (_status == DownloadStatus.error) ...[
                Icon(Icons.error_outline_rounded,
                    size: 56, color: colorScheme.error),
              ] else if (_status == DownloadStatus.completed) ...[
                Icon(Icons.check_circle_outline_rounded,
                    size: 56, color: colorScheme.tertiary),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                _status == DownloadStatus.downloading
                    ? 'Downloading...'
                    : (_status == DownloadStatus.error
                        ? 'Download Failed'
                        : 'Download Complete!'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _status == DownloadStatus.completed
                      ? colorScheme.tertiary
                      : (_status == DownloadStatus.error
                          ? colorScheme.error
                          : colorScheme.onSurface),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // File name
              Text(
                widget.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Progress Bar
              if (_status == DownloadStatus.downloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 8,
                    backgroundColor: colorScheme.outline.withOpacity(0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Percentage
                Text(
                  '${_progress.toStringAsFixed(0)}%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),

                // Bytes info
                if (_totalBytes > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatBytes(_bytesReceived)} of ${_formatBytes(_totalBytes)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],

              // Success message
              if (_status == DownloadStatus.completed) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Opening file...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Error message
              if (_status == DownloadStatus.error && _errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
