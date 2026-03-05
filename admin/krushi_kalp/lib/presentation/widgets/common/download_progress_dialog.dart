import 'package:flutter/material.dart';
import '../../../data/services/download_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

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
          // Show success state for 3 seconds before auto-closing
          await Future.delayed(const Duration(seconds: 3));
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
    return PopScope(
      canPop: _status != DownloadStatus.downloading,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              if (_status == DownloadStatus.downloading) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ] else if (_status == DownloadStatus.error) ...[
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
              ] else if (_status == DownloadStatus.completed) ...[
                const Icon(Icons.check_circle_outline,
                    size: 48, color: AppColors.success),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                _status == DownloadStatus.downloading
                    ? 'Downloading...'
                    : (_status == DownloadStatus.error
                        ? 'Download Failed'
                        : 'Download Complete!'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _status == DownloadStatus.completed
                          ? AppColors.success
                          : (_status == DownloadStatus.error
                              ? AppColors.error
                              : AppColors.textPrimary),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // File name
              Text(
                widget.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Progress Bar
              if (_status == DownloadStatus.downloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.neutral200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Percentage
                Text(
                  '${_progress.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 32,
                      ),
                ),

                // Bytes info
                if (_totalBytes > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatBytes(_bytesReceived)} of ${_formatBytes(_totalBytes)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],

              // Error message
              if (_status == DownloadStatus.error && _errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
