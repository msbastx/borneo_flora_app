import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/storage/app_prefs.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_messenger.dart';
import '../features/home/home_screen.dart';
import '../features/home/flora_index_screen.dart';
import '../features/guide/capture_guide_screen.dart';
import '../features/history/history_screen.dart';
import '../features/identification/identification_controller.dart';
import '../features/identification/identification_screen.dart';
import '../features/identification/identification_theme.dart';
import '../features/identification/models/identification_source.dart';
import '../features/profile/reporter_profile_dialog.dart';
import '../features/report/report_config.dart';
import '../features/report/models/report_queue_item.dart';
import '../features/report/report_status_screen.dart';
import '../features/report/repositories/report_queue_repository.dart';
import '../features/report/services/queue_runner.dart';
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
  final ReportQueueRepository _reportQueue = ReportQueueRepository.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<QueueRunResult>? _queueResultSub;

  int _index = _homeTab;
  bool _useWebViewCatalog = true; // WebView katalog utama; aset statis tetap tersedia sebagai fallback offline

  @override
  void initState() {
    super.initState();

    // Notifikasi setiap kali satu putaran pengiriman antrean selesai.
    _queueResultSub = _reportQueue.results.listen(_announceQueueResult);

    // Coba kirim antrean laporan yang masih PENDING saat aplikasi baru dibuka
    _processQueueSafely();

    // Pengguna baru: tanya nama dan email setelah panduan selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askProfileOnce());

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
      return null;
    }));
  }

  /// Formulir nama dan email muncul sekali, setelah panduan pertama selesai.
  Future<void> _askProfileOnce() async {
    if (await AppPrefs.hasAskedProfile()) return;
    if (!mounted) return;
    await showReporterProfileDialog(context, firstTime: true);
  }

  void _announceQueueResult(QueueRunResult result) {
    if (result.failed.isNotEmpty) {
      final ReportQueueItem first = result.failed.first;
      AppMessenger.show(
        result.failed.length == 1
            ? '${first.reportType.label} ditolak server. ${first.lastError ?? ''}'.trim()
            : '${result.failed.length} laporan ditolak server.',
        action: SnackBarAction(label: 'Lihat', onPressed: _openReportStatus),
        duration: const Duration(seconds: 6),
      );
      return;
    }
    if (result.sent.isNotEmpty) {
      final String text = result.sent.length == 1
          ? '${result.sent.first.reportType.label} berhasil terkirim ke server.'
          : '${result.sent.length} laporan berhasil terkirim ke server.';
      AppMessenger.show(result.pendingCount > 0
          ? '$text ${result.pendingCount} laporan masih menunggu.'
          : text);
      return;
    }
    if (result.stoppedOffline && result.pendingCount > 0) {
      AppMessenger.show(
        'Server belum dapat dijangkau. ${result.pendingCount} laporan menunggu '
        'dan dikirim otomatis saat jaringan tersedia.',
      );
    }
  }

  void _openReportStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportStatusScreen()),
    );
  }

  @override
  void dispose() {
    _queueResultSub?.cancel();
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
          backgroundColor: AppColors.base100,
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
                    leading: const Icon(Icons.person_outline, color: AppColors.darkGreen),
                    title: const Text('Profil Pelapor'),
                    subtitle: const Text('Nama, email, dan izin kirim otomatis foto dataset.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      showReporterProfileDialog(this.context);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.outbox_outlined, color: AppColors.darkGreen),
                    title: const Text('Status Laporan'),
                    subtitle: const Text('Lihat laporan yang terkirim, menunggu, atau ditolak.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openReportStatus();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.darkGreen),
                    title: const Text('Kirim Antrean Laporan Sekarang'),
                    subtitle: const Text('Kirim laporan yang masih menunggu ke server.'),
                    onTap: () {
                      Navigator.of(context).pop();
                      AppMessenger.show('Mengirim antrean laporan ke server...');
                      _processQueueSafely();
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
        backgroundColor: AppColors.base200,
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
              onOpenCatalog: () => _goTo(2),
              onOpenMap: () => _goTo(3),
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