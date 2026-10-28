import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';

class PortalWebViewTab extends StatefulWidget {
  const PortalWebViewTab({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<PortalWebViewTab> createState() => _PortalWebViewTabState();
}

class _PortalWebViewTabState extends State<PortalWebViewTab> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF2EFE8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header kecil dengan tombol Refresh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EFE8),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.darkGreen.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, size: 18, color: AppColors.darkGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: AppColors.darkGreen),
                  onPressed: _reload,
                  tooltip: 'Muat Ulang',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Isi WebView
          Expanded(
            child: Stack(
              children: [
                if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.darkGreen),
                          const SizedBox(height: 12),
                          const Text(
                            'Gagal memuat halaman portal',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pastikan perangkat terhubung ke jaringan dan server (${widget.url}) sedang aktif.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.darkGreen,
                              foregroundColor: const Color(0xFFF2EFE8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  WebViewWidget(controller: _controller),
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.darkGreen,
                  ),
              ],
            ),
          ),
          // Ruang agar konten bawah tidak tertutup floating navbar
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 76),
        ],
      ),
    );
  }
}