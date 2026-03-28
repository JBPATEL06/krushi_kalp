import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:krushi_kalp/data/services/performance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/presentation/providers/auth_notifier.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final File file;
  final String? password;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.file,
    this.password,
    required this.title,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool _isNightMode = false;
  DateTime? _openedAt; // NEW — tracks when PDF was opened

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now(); // NEW
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (pages == 0) {
      _isNightMode = Theme.of(context).brightness == Brightness.dark;
    }
  }

  @override
  void dispose() {
    // NEW — calculate read duration and update streak if >= 5 minutes
    if (_openedAt != null) {
      final durationSeconds = DateTime.now().difference(_openedAt!).inSeconds;
      if (durationSeconds >= 300) {
        final userId = ref.read(authNotifierProvider).user?.id ?? '';
        if (userId.isNotEmpty) {
          PerformanceService.instance
              .updateUserStreak(userId, durationSeconds, 'resource_read')
              .ignore();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.dark_mode : Icons.light_mode,
              color: _isNightMode ? Colors.amber : theme.colorScheme.primary,
            ),
            tooltip: 'Toggle Night Mode',
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            key: ValueKey(_isNightMode),
            filePath: widget.file.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: false,
            pageSnap: false,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            password: widget.password, // Pass the password here
            nightMode: _isNightMode,
            onRender: (p) {
              setState(() {
                pages = p;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {},
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
    );
  }
}
