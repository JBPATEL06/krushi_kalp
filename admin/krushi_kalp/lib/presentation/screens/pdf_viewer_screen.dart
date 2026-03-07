import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              final xFile = XFile(widget.file.path,
                  name: '${widget.title}.pdf', mimeType: 'application/pdf');
              await Share.shareXFiles([xFile], text: 'PDF: ${widget.title}');
            },
            tooltip: 'Share/Download PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.file.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: false,
            pageSnap: false,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            password: widget.password,
            onRender: (pages) {
              setState(() {
                this.pages = pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              debugPrint(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              debugPrint('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              debugPrint('goto uri: $uri');
            },
            onPageChanged: (int? page, int? total) {
              debugPrint('page change: $page/$total');
              setState(() {
                currentPage = page;
              });
            },
          ),
          if (errorMessage.isEmpty)
            if (!isReady)
              Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            else
              const SizedBox.shrink()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.error),
                ),
              ),
            )
        ],
      ),
    );
  }
}
