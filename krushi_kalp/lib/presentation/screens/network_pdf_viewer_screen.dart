import 'package:flutter/material.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../core/theme/app_spacing.dart';

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
  final GlobalKey _viewerKey = GlobalKey();
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  late final PdfTextSearcher _searcher;

  bool _isSearching = false;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _searcher = PdfTextSearcher(_controller);
    _searcher.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_totalPages == 0) {
      _isNightMode = Theme.of(context).brightness == Brightness.dark;
    }
  }

  @override
  void dispose() {
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

    final viewer = PdfViewer.uri(
      Uri.parse(widget.url),
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
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                totalBytes != null 
                  ? 'Loading: ${(bytesDownloaded / totalBytes * 100).toStringAsFixed(0)}%' 
                  : 'Streaming PDF...',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: chromeGrey,
      appBar: AppBar(
        backgroundColor: chromeGrey,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isSearching 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isSearching = false))
          : IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(fontSize: context.sp(16), color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Online', style: TextStyle(color: Colors.greenAccent, fontSize: context.sp(10))),
                  ),
                ],
              ),
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
                size: context.sp(20),
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
