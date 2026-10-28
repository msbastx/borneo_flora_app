import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';

/// Aplikasi memakai halaman katalog/peta yang sudah disediakan server Django.
/// URL diinjeksikan melalui ReportConfig agar lokal dan production bisa diganti.
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
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
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
    final Color background = const Color(0xFFF2EFE8);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: background,
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
                  tooltip: 'Muat ulang',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_errorMessage != null)
                  ColoredBox(
                    color: background,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: AppColors.darkGreen,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Gagal memuat halaman portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Periksa Docker/server dan alamat jaringan perangkat.\n${widget.url}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGreen.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.darkGreen.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.darkGreen,
                                foregroundColor: background,
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
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  WebViewWidget(controller: _controller),
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.darkGreen,
                    backgroundColor: Color(0xFFDADFD4),
                  ),
              ],
            ),
          ),
          // Ruang agar konten bawah tidak tertutup floating navbar.
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 76),
        ],
      ),
    );
  }
}
