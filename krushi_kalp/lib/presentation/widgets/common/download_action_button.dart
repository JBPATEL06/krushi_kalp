import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/download_service.dart';
import '../../../core/theme/app_colors.dart';

class DownloadActionButton extends StatefulWidget {
  final String filename;
  final String? url;
  final String startLabel; // e.g., "Start" or "Open"
  final Future<void> Function()
      onAction; // Called when Start/Open is clicked (or after download)
  final bool isFullWidth;
  final String? userId;

  const DownloadActionButton({
    super.key,
    required this.filename,
    required this.url,
    this.startLabel = "Start",
    required this.onAction,
    this.isFullWidth = true,
    this.userId,
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

    final currentUserId =
        widget.userId ?? Supabase.instance.client.auth.currentUser?.id;

    final exists = await DownloadService()
        .isFileDownloaded(widget.filename, userId: currentUserId);
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
    if (_checking) {
      return const SizedBox(
        height: 48,
        child: Center(
            child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final label = _isDownloaded ? widget.startLabel : "Download";
    final icon =
        _isDownloaded ? Icons.visibility_outlined : Icons.download_rounded;
    final color = _isDownloaded ? AppColors.primary : AppColors.secondary;

    Widget button = ElevatedButton.icon(
      onPressed: () async {
        // Execute the action (download or open)
        await widget.onAction();
        // Check status again to update label (e.g. Download -> Open)
        if (mounted) {
          _checkStatus();
        }
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(widget.isFullWidth ? double.infinity : 0, 48),
      ),
    );

    return button;
  }
}
