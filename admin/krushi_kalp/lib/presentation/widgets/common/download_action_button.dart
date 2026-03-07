import 'package:flutter/material.dart';
import '../../../data/services/download_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class DownloadActionButton extends StatefulWidget {
  final String filename;
  final String? url;
  final String startLabel;
  final Future<void> Function() onAction;
  final bool isFullWidth;

  const DownloadActionButton({
    super.key,
    required this.filename,
    required this.url,
    this.startLabel = "Start",
    required this.onAction,
    this.isFullWidth = true,
  });

  @override
  State<DownloadActionButton> createState() => _DownloadActionButtonState();
}

class _DownloadActionButtonState extends State<DownloadActionButton> {
  bool _isDownloaded = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    final exists = await DownloadService().isFileDownloaded(widget.filename);
    if (mounted) {
      setState(() {
        _isDownloaded = exists;
        _checking = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant DownloadActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filename != widget.filename) {
      _checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_checking) {
      return SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
      );
    }

    final label = _isDownloaded ? widget.startLabel : "Download";
    final icon =
        _isDownloaded ? Icons.visibility_rounded : Icons.download_rounded;
    final buttonColor =
        _isDownloaded ? colorScheme.primary : colorScheme.secondary;

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          await widget.onAction();
          if (mounted) {
            _checkStatus();
          }
        },
        icon: Icon(icon, color: colorScheme.onPrimary, size: 20),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
