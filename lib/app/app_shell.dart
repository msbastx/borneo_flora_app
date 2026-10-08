import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';
import '../features/identification/identification_controller.dart';
import '../features/identification/identification_screen.dart';
import '../features/identification/identification_theme.dart';
import '../features/identification/models/identification_source.dart';
import '../shared/widgets/coming_soon_tab.dart';
import '../shared/widgets/navbar.dart';

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
  int _index = _homeTab;

  @override
  void dispose() {
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
        // Konten tab memanjang sampai ke belakang navbar melayang.
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            FloraHomeScreen(
              onOpenCamera: () =>
                  _openIdentification(IdentificationSource.camera),
              onOpenGallery: () =>
                  _openIdentification(IdentificationSource.gallery),
            ),
            IdentificationScreen(controller: _ident),
            const ComingSoonTab(
              title: 'Indeks Flora',
              icon: Icons.menu_book_outlined,
            ),
            const ComingSoonTab(
              title: 'Peta Sebaran',
              icon: Icons.map_outlined,
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
