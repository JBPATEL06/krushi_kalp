import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/models/resource.dart';
import '../data/services/download_service.dart';
import '../presentation/screens/pdf_viewer_screen.dart';
import '../presentation/widgets/common/download_progress_dialog.dart';

class ResourceHelper {
  /// Unified method to open a resource inside the app.
  /// Strictly avoids external app switches (like Google Drive).
  static Future<void> openResource({
    required BuildContext context,
    required Resource resource,
    String? userId,
  }) async {
    final filename = 'resource_${resource.id}.pdf';
    
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to access resources.')),
      );
      return;
    }

    // 1. Check if already downloaded
    final isDownloaded = await DownloadService().isFileDownloaded(filename, userId: userId);

    if (isDownloaded) {
      final path = await DownloadService().getLocalPath(filename, userId: userId);
      final file = File(path);
      
      if (await file.exists()) {
        if (!context.mounted) return;
        _navigateToViewer(context, file, resource.title);
        return;
      }
    }

    // 2. Not downloaded or file missing - check for URL
    if (resource.fileUrl == null || resource.fileUrl!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource file is not available.')),
        );
      }
      return;
    }

    // 3. Show download dialog and then open
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DownloadProgressDialog(
        url: resource.fileUrl!,
        filename: filename,
        displayName: resource.title,
        userId: userId,
        onComplete: (path) {
          // Open file after download
          if (!context.mounted) return;
          _navigateToViewer(context, File(path), resource.title);
        },
        onError: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download failed. Please try again.')),
            );
          }
        },
      ),
    );
  }

  static void _navigateToViewer(BuildContext context, File file, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          file: file,
          title: title,
        ),
      ),
    );
  }
}
