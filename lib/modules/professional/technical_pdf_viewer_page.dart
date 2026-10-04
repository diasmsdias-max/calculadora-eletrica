import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class TechnicalPdfViewerPage extends StatefulWidget {
  final String title;
  final String localPath;

  const TechnicalPdfViewerPage({
    super.key,
    required this.title,
    required this.localPath,
  });

  @override
  State<TechnicalPdfViewerPage> createState() => _TechnicalPdfViewerPageState();
}

class _TechnicalPdfViewerPageState extends State<TechnicalPdfViewerPage> {
  int? _pages;
  int _currentPage = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final file = File(widget.localPath);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_pages != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text('${_currentPage + 1}/$_pages'),
              ),
            ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != true) {
            return const _ViewerMessage(
              icon: Icons.file_present_outlined,
              message: 'O arquivo offline não foi encontrado neste aparelho.',
            );
          }
          if (_error != null) {
            return _ViewerMessage(
              icon: Icons.error_outline,
              message: 'Não foi possível abrir este PDF.\n$_error',
            );
          }
          return PDFView(
            filePath: widget.localPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) {
              if (mounted) {
                setState(() => _pages = pages);
              }
            },
            onPageChanged: (page, _) {
              if (mounted && page != null) {
                setState(() => _currentPage = page);
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() => _error = error.toString());
              }
            },
          );
        },
      ),
    );
  }
}

class _ViewerMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ViewerMessage({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
