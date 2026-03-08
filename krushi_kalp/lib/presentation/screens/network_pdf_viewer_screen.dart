import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_spacing.dart';

/// PDF Viewer that streams from network URL (temporary cache, not saved permanently)
class NetworkPdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const NetworkPdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<NetworkPdfViewerScreen> createState() => _NetworkPdfViewerScreenState();
}

class _NetworkPdfViewerScreenState extends State<NetworkPdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isNightMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize night mode based on theme if not manually set
    if (_totalPages == 0) {
      _isNightMode = Theme.of(context).brightness == Brightness.dark;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Download to temporary cache (will be cleared by system)
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }

      // Save to temp directory (not permanent storage)
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up temp file when done
    if (_localPath != null) {
      File(_localPath!).delete().catchError((_) => File(''));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors
          .black, // Dark background for PDF viewer is usually preferred regardless of theme
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: context.sp(16)), // FIXED
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(
                    fontSize: context.sp(12),
                    color: theme.colorScheme.onSurfaceVariant), // FIXED
              ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.close, size: context.sp(24)), // FIXED
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.dark_mode : Icons.light_mode,
              color: _isNightMode ? Colors.amber : theme.colorScheme.primary,
              size: context.sp(20), // FIXED
            ),
            tooltip: 'Toggle Night Mode',
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_outlined,
                    size: context.sp(16),
                    color: theme.colorScheme.primary), // FIXED
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: context.sp(12), // FIXED
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Loading PDF...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: context.sp(16), // FIXED
                  ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: context.sp(64),
                  color: theme.colorScheme.error), // FIXED
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Failed to load PDF',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(20), // FIXED
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: context.sp(14), // FIXED
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: Icon(Icons.refresh, size: context.sp(18)), // FIXED
                label: Text('Retry',
                    style: TextStyle(fontSize: context.sp(14))), // FIXED
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const Center(child: Text('No PDF loaded'));
    }

    return PDFView(
      key: ValueKey(_isNightMode),
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.WIDTH,
      preventLinkNavigation: false,
      nightMode: _isNightMode,
      onRender: (pages) {
        if (mounted) {
          setState(() {
            _totalPages = pages ?? 0;
            _currentPage = 1;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      },
      onPageError: (page, error) {},
      onViewCreated: (PDFViewController controller) {
        // Controller can be used for additional controls if needed
      },
      onPageChanged: (int? page, int? total) {
        if (mounted && page != null) {
          setState(() {
            _currentPage = page + 1;
          });
        }
      },
    );
  }
}
