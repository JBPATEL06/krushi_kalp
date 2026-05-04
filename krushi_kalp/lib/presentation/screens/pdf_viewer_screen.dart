import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
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
  final GlobalKey _viewerKey = GlobalKey();
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  late final PdfTextSearcher _searcher;
  
  bool _isSearching = false;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isNightMode = false;
  DateTime? _openedAt;
  String? _userId; // captured in initState, safe to use in dispose

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _searcher = PdfTextSearcher(_controller);
    _loadInitialNightMode();
    _searcher.addListener(() => setState(() {}));
    // Capture userId now — ref is NOT safe to use in dispose()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userId = ref.read(authProvider).user?.id;
      }
    });
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
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_openedAt != null) {
      final durationSeconds = DateTime.now().difference(_openedAt!).inSeconds;
      if (durationSeconds >= 300 && _userId != null && _userId!.isNotEmpty) {
        PerformanceService.instance
            .updateUserStreak(_userId!, durationSeconds, 'resource_read')
            .ignore();
      }
    }
    _searchController.dispose();
    _searcher.dispose();
    super.dispose();
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF323639),
        title: const Text('Go to Page', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pageController,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter page number',
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _controller.goToPage(pageNumber: page);
              }
              Navigator.pop(context);
            },
            child: const Text('Go', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color chromeGrey = const Color(0xFF323639);

    final viewer = PdfViewer.file(
      widget.file.path,
      key: _viewerKey,
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor: _isNightMode ? Colors.black : chromeGrey,
        enableTextSelection: true,
        pagePaintCallbacks: [
          _searcher.pageTextMatchPaintCallback,
        ],
        onViewerReady: (document, controller) {
          if (mounted) {
            setState(() => _totalPages = document.pages.length);
          }
        },
        onPageChanged: (pageNumber) {
          if (pageNumber != null && mounted) {
            setState(() => _currentPage = pageNumber);
          }
        },
      ),
    );

    return Scaffold(
      backgroundColor: chromeGrey,
      appBar: AppBar(
        backgroundColor: chromeGrey,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search text...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (text) => _searcher.startTextSearch(text),
              )
            : Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _searcher.hasMatches ? _searcher.goToPrevMatch : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: _searcher.hasMatches ? _searcher.goToNextMatch : null,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searcher.resetTextSearch();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.pin_end),
              tooltip: 'Go to Page',
              onPressed: _showJumpToPageDialog,
            ),
            IconButton(
              icon: Icon(
                _isNightMode ? Icons.dark_mode : Icons.light_mode,
                color: _isNightMode ? Colors.amber : Colors.white,
              ),
              onPressed: () => setState(() => _isNightMode = !_isNightMode),
            ),
          ],
        ],
      ),
      body: _isNightMode
          ? ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -1, 0, 0, 0, 255, // Invert Red
                0, -1, 0, 0, 255, // Invert Green
                0, 0, -1, 0, 255, // Invert Blue
                0, 0, 0, 1, 0, // Alpha
              ]),
              child: viewer,
            )
          : viewer,
      bottomNavigationBar: _totalPages > 0
          ? Container(
              color: chromeGrey,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_searcher.hasMatches)
                     Text(
                      'Result ${(_searcher.currentIndex ?? -1) + 1} of ${_searcher.matches.length}',
                      style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
