import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  WebViewController? _controller; // nullable for web fallback
  bool _isLoading = true;
  bool _hasError = false;
  late String _viewableUrl;

  @override
  void initState() {
    super.initState();
    _viewableUrl = _convertToViewableUrl(widget.pdfUrl);
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      // On web we don't initialize native WebView; just stop loading indicator
      _isLoading = false;
    }
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
    if (kIsWeb) return; // safety guard
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_viewableUrl));
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
              _controller?.reload();
            },
          ),
        ],
      ),
      body: kIsWeb ? _buildWebFallback() : _buildMobileWebView(),
    );
  }

  Widget _buildMobileWebView() {
    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_isLoading) _buildLoadingOverlay(),
        if (_hasError && !_isLoading) _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildWebFallback() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Web PDF Viewer (Fallback)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Embedded WebView is not available on Web builds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(_viewableUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.open_in_new),
                    label: Text('Open PDF in New Tab'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text('Loading PDF...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
              SizedBox(height: 16),
              Text('Could not load PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Please check your internet connection', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _initializeWebView();
                  _controller?.reload();
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
