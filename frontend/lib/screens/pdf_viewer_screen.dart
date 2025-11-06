import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final int materialId;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.materialId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _trackView();
  }

  Future<void> _trackView() async {
    try {
      await ApiService.incrementDownload(widget.materialId);
    } catch (e) {
      // Silent fail for tracking
    }
  }

  String _convertToViewableUrl(String url) {
    // Convert Google Drive sharing link to embedded viewer link
    if (url.contains('drive.google.com')) {
      // Extract file ID from various Google Drive URL formats
      final patterns = [
        RegExp(r'/d/([a-zA-Z0-9_-]+)'),
        RegExp(r'id=([a-zA-Z0-9_-]+)'),
      ];
      
      for (var pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null) {
          final fileId = match.group(1);
          // Return embedded preview URL that doesn't allow download
          return 'https://drive.google.com/file/d/$fileId/preview';
        }
      }
    }
    
    // For direct PDF URLs, use Google Docs viewer
    if (url.endsWith('.pdf') || url.contains('.pdf')) {
      return 'https://docs.google.com/gview?embedded=true&url=$url';
    }
    
    return url;
  }

  void _initializeWebView() {
    final viewableUrl = _convertToViewableUrl(widget.pdfUrl);
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(viewableUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasError && !_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorRed,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Could not load PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your internet connection',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          _initializeWebView();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
