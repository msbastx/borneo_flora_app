import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';
import '../features/home/flora_index_screen.dart';
import '../features/guide/capture_guide_screen.dart';
import '../features/history/history_screen.dart';
import '../features/identification/identification_controller.dart';
import '../features/identification/identification_screen.dart';
import '../features/identification/identification_theme.dart';
import '../features/identification/models/identification_source.dart';
import '../features/report/report_config.dart';
import '../features/report/repositories/report_queue_repository.dart';
import '../shared/widgets/navbar.dart';
import '../shared/widgets/portal_webview_tab.dart';

/// Kerangka utama: empat tab dan navbar bersama. Urutan tab mengikuti
/// kNavDestinations (HOME, IDENT, INDEKS, PETA).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _homeTab = 0;
  static const int _identTab = 1;

  final IdentificationController _ident = IdentificationController();
  late final ReportQueueRepository _reportQueue;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int _index = _homeTab;
  bool _useWebViewCatalog = true; // WebView katalog utama; aset statis tetap tersedia sebagai fallback offline

  @override
  void initState() {
    super.initState();

    // Inisialisasi Dio & Antrean Laporan Offline-First ke Server Lokal / Production
    final dio = Dio(BaseOptions(baseUrl: ReportConfig.apiBaseUrl));
    _reportQueue = ReportQueueRepository(dio: dio);

    // Coba kirim antrean laporan yang masih PENDING saat aplikasi baru dibuka
    _processQueueSafely();

    // Pantau perubahan jaringan: otomatis kirim antrean saat internet kembali aktif
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        _processQueueSafely();
      }
    });
  }

  void _processQueueSafely() {
    unawaited(_reportQueue.processQueue().catchError((Object error) {
      debugPrint('[ReportQueue] Gagal memproses antrean: $error');
    }));
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _ident.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    // Model baru dimuat saat tab Identifikasi pertama kali dibuka.
    if (index == _identTab) _ident.loadModel();
    setState(() => _index = index);
  }

  void _openIdentification(IdentificationSource source) {
    _ident.setSource(source);
    _goTo(_identTab);
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'guide':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaptureGuideScreen(
              onFinish: () => Navigator.of(context).pop(),
              onSkip: () => Navigator.of(context).pop(),
            ),
          ),
        );
        break;
      case 'history':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HistoryScreen(
              repository: _ident.history,
              resolve: _ident.resolveRecord,
            ),
          ),
        );
        break;
      case 'settings':
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          backgroundColor: const Color(0xFFFAF5FA),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Server Aktif: ${ReportConfig.portalBaseUrl}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gunakan WebView untuk Tab Indeks'),
                    subtitle: const Text(
                      'Aktifkan untuk memuat katalog langsung dari server portal (/repository/).',
                    ),
                    value: _useWebViewCatalog,
                    onChanged: (val) {
                      setState(() => _useWebViewCatalog = val);
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.darkGreen),
                    title: const Text('Sinkronkan Antrean Laporan Sekarang'),
                    subtitle: const Text('Kirim laporan tertunda (PENDING) ke server.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _processQueueSafely();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Memproses antrean laporan ke server...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        break;
    }
  }

  /// Tombol Kembali: tutup hasil dulu, lalu pulang ke tab Home.
  void _handleBack() {
    if (_index == _identTab && _ident.showsResult) {
      _ident.reset();
    } else {
      _goTo(_homeTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == _homeTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            FloraHomeScreen(
              onOpenCamera: () =>
                  _openIdentification(IdentificationSource.camera),
              onOpenGallery: () =>
                  _openIdentification(IdentificationSource.gallery),
              onMenuSelected: _onMenuSelected,
            ),
            IdentificationScreen(controller: _ident),
            // Tab 2: INDEKS (Bisa Aset Statis Offline atau WebView Portal)
            _useWebViewCatalog
                ? const PortalWebViewTab(
              title: 'Katalog Spesies Portal',
              url: ReportConfig.catalogWebViewUrl,
            )
                : const FloraIndexScreen(),
            // Tab 3: PETA DISTRIBUSI (WebView langsung ke /gis/map/species/)
            const PortalWebViewTab(
              title: 'Peta Sebaran Spesies Kalimantan',
              url: ReportConfig.mapDistributionWebViewUrl,
            ),
          ],
        ),
        bottomNavigationBar: Navbar(
          activeIndex: _index,
          onTap: _goTo,
          backgroundColor: _index == _identTab
              ? IdentColors.surface
              : AppColors.navBackground,
        ),
      ),
    );
  }
}