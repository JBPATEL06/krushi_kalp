import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:krushi_kalp/data/services/performance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_kalp/presentation/providers/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadInitialNightMode();
  }

  Future<void> _loadInitialNightMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('pdf_theme') ?? 'light';
      if (mounted) {
        setState(() {
          _isNightMode = savedTheme == 'dark';
        });
      }
    } catch (e) {
      // Ignored, defaults to false
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the Profile settings, removed system brightness override.
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
    final Color chromeGrey = const Color(0xFF323639);
    
    return Scaffold(
      backgroundColor: chromeGrey,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
        backgroundColor: chromeGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.dark_mode : Icons.light_mode,
              color: _isNightMode ? Colors.amber : Colors.white,
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
          Container(
            color: chromeGrey,
            child: PDFView(
              key: ValueKey('${_isNightMode}_$isReady'),
              filePath: widget.file.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true, // Keep spacing but background makes it distinct
              pageFling: true,
              pageSnap: false, // Fluid scrolling like Chrome
              defaultPage: currentPage!,
              fitPolicy: FitPolicy.WIDTH,
              preventLinkNavigation: false,
              password: widget.password,
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
          ),
          if (currentPage != null && pages != null && isReady)
             Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${currentPage! + 1} of $pages',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          errorMessage.isEmpty
              ? !isReady
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
                )
        ],
      ),
    );
  }
}
