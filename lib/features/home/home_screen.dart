import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/dummy_data.dart';
import 'widgets/flora_index_header.dart';
import 'widgets/flora_row.dart';
import 'widgets/home_header.dart';
import 'widgets/viewfinder_card.dart';

/// Tab Home. Navbar dan Scaffold dimiliki AppShell, layar ini hanya
/// meminta shell membuka tab Identifikasi lewat callback.
class FloraHomeScreen extends StatelessWidget {
  const FloraHomeScreen({
    super.key,
    required this.onOpenCamera,
    required this.onOpenGallery,
  });

  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    'Apa yang\nanda temukan\nhari ini?',
                    style: AppText.homeTitle,
                  ),
                  const SizedBox(height: 28),
                  ViewfinderCard(
                    onCapture: onOpenCamera,
                    onGallery: onOpenGallery,
                  ),
                  const SizedBox(height: 32),
                  FloraIndexHeader(count: dummyFloraList.length),
                ],
              ),
            ),
          ),
          // Baris dibangun bertahap, hanya yang tampil di layar.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: dummyFloraList.length,
              itemBuilder: (_, i) => FloraRow(item: dummyFloraList[i]),
            ),
          ),
          // Ruang untuk navbar melayang.
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ),
        ],
      ),
    );
  }
}
