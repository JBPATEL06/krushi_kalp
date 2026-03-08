import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../domain/models/resource.dart';
import '../../../../data/services/secure_file_service.dart';
import '../screens/pdf_viewer_screen.dart';

class ResourceDetailDialog extends StatefulWidget {
  final Resource resource;
  final bool isPurchased; // NEW
  final VoidCallback? onBuyTap; // NEW

  const ResourceDetailDialog({
    super.key,
    required this.resource,
    this.isPurchased = false,
    this.onBuyTap,
  });

  @override
  State<ResourceDetailDialog> createState() => _ResourceDetailDialogState();
}

class _ResourceDetailDialogState extends State<ResourceDetailDialog> {
  final SecureFileService _fileService = SecureFileService();
  bool _isDownloading = false;
  File? _downloadedFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkFileStatus();
  }

  Future<void> _checkFileStatus() async {
    final isDownloaded =
        await _fileService.isFileDownloaded(widget.resource.title);
    if (isDownloaded) {
      final docsDir = await _fileService.getSecureDirectory();
      final cleanName =
          widget.resource.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      setState(() {
        _downloadedFile = File('${docsDir.path}/$cleanName');
      });
    }
  }

  Future<void> _downloadAndOpen() async {
    if (widget.resource.fileUrl == null) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final file = await _fileService.downloadSecurely(
          widget.resource.fileUrl!, widget.resource.title);

      if (mounted) {
        setState(() {
          _downloadedFile = file;
          _isDownloading = false;
        });
        _openFile(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = "Download Failed: $e";
        });
      }
    }
  }

  void _openFile(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerScreen(file: file, title: widget.resource.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              widget.resource.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Date & Category
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  widget.resource.createdAt.toString().split(' ')[0],
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (widget.resource.category != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.resource.category!,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (widget.resource.description != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.resource.description!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
              ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Action Button
            // Action Button
            if (_isDownloading)
              const Center(child: CircularProgressIndicator())
            else if (widget.isPurchased || widget.resource.price == 0)
              ElevatedButton.icon(
                onPressed: _downloadAndOpen,
                icon: Icon(_downloadedFile != null
                    ? Icons.visibility
                    : Icons.download),
                label: Text(_downloadedFile != null ? 'Open' : 'Download Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: widget.onBuyTap,
                icon: const Icon(Icons.shopping_cart),
                label: Text('Buy Now for ₹${widget.resource.price}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
