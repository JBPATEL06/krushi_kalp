import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isFullscreen = false;
  bool _isLandscape = false;
  bool _showHint = false;
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _searcher = PdfTextSearcher(_controller);
    _loadInitialNightMode();
    _checkAndShowHint();
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

  Future<void> _checkAndShowHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('pdf_viewer_hint_shown') ?? false;
      if (!hasShown && mounted) {
        setState(() => _showHint = true);
        await prefs.setBool('pdf_viewer_hint_shown', true);
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() => _showHint = false);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _toggleFullscreen(bool enter) {
    setState(() {
      _isFullscreen = enter;
    });
    SystemChrome.setEnabledSystemUIMode(
      enter ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
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

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullscreen) {
          _toggleFullscreen(false);
        }
      },
      child: Scaffold(
        backgroundColor: chromeGrey,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: _AnimatedAppBar(
          isFullscreen: _isFullscreen,
          child: AppBar(
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
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                      _toggleFullscreen(false);
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'theme') {
                      setState(() {
                        _isNightMode = !_isNightMode;
                      });
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setString('pdf_theme', _isNightMode ? 'dark' : 'light');
                      });
                    } else if (value == 'jump') {
                      _showJumpToPageDialog();
                    } else if (value == 'fullscreen') {
                      _toggleFullscreen(!_isFullscreen);
                    } else if (value == 'horizontal') {
                      _toggleOrientation();
                    }
                  },
                  itemBuilder: (context) {
                    final theme = Theme.of(context);
                    final onSurface = theme.colorScheme.onSurface;
                    return [
                      PopupMenuItem(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(
                              _isNightMode ? Icons.light_mode : Icons.dark_mode,
                              color: _isNightMode ? Colors.amber : onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isNightMode ? 'Light Theme' : 'Dark Theme',
                              style: TextStyle(color: onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'jump',
                        child: Row(
                          children: [
                            Icon(Icons.pin_end, color: onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'Go to Page',
                              style: TextStyle(color: onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'fullscreen',
                        child: Row(
                          children: [
                            Icon(
                              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isFullscreen ? 'Exit Full Screen' : 'Full Screen',
                              style: TextStyle(color: onSurface),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'horizontal',
                        child: Row(
                          children: [
                            Icon(
                              Icons.screen_rotation_rounded,
                              color: _isLandscape ? Colors.blue : onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLandscape ? 'Vertical View' : 'Horizontal View',
                              style: TextStyle(color: onSurface),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ],
          ),
        ),
        body: Stack(
          children: [
            Listener(
              onPointerDown: (event) {
                _pointerDownPosition = event.position;
                _pointerDownTime = DateTime.now();
              },
              onPointerUp: (event) {
                if (_pointerDownPosition != null && _pointerDownTime != null) {
                  final difference = event.position - _pointerDownPosition!;
                  final duration = DateTime.now().difference(_pointerDownTime!);
                  if (difference.distance < 10 && duration.inMilliseconds < 300) {
                    _toggleFullscreen(!_isFullscreen);
                  }
                }
              },
              child: _isNightMode
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
            ),
            if (_showHint)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tap to show/hide controls',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _totalPages > 0
            ? AnimatedSlide(
                offset: _isFullscreen ? const Offset(0, 1) : Offset.zero,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _isFullscreen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
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
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _AnimatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget child;
  final bool isFullscreen;

  const _AnimatedAppBar({required this.child, required this.isFullscreen});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: isFullscreen ? const Offset(0, -1) : Offset.zero,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isFullscreen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: child,
      ),
    );
  }

  @override
  Size get preferredSize => child.preferredSize;
}
