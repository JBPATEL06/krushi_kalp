import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
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
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool _isNightMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (pages == 0) {
      _isNightMode = Theme.of(context).brightness == Brightness.dark;
    }
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
            onLinkHandler: (String? uri) {
              
            },
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
