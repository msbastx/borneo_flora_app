import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/dummy_data.dart';
import 'widgets/flora_index_header.dart';
import 'widgets/flora_row.dart';
import 'widgets/home_header.dart';
import 'widgets/viewfinder_card.dart';

/// Tab Home — hero selaras kalimantanbio.com + identifikasi mobile.
class FloraHomeScreen extends StatelessWidget {
  const FloraHomeScreen({
    super.key,
    required this.onOpenCamera,
    required this.onOpenGallery,
    required this.onMenuSelected,
    required this.onOpenCatalog,
    required this.onOpenMap,
  });

  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.base200,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeader(onMenuSelected: onMenuSelected),
                    const SizedBox(height: 20),
                    const _LiveDataBadge(),
                    const SizedBox(height: 20),
                    Text('Temukan', style: AppText.homeTitle),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          portalHeroGradient.createShader(bounds),
                      child: Text(
                        'Jantung Borneo',
                        style: AppText.homeTitle.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Portal informasi keanekaragaman hayati dan konservasi '
                      'Kalimantan. Akses data sebaran spesies, kondisi hutan, '
                      'dan riset terbaru untuk pelestarian alam.',
                      style: AppText.homeSubtitle,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _PortalPrimaryButton(
                          label: 'Jelajahi Database',
                          icon: Icons.arrow_forward_rounded,
                          onTap: onOpenCatalog,
                        ),
                        _PortalOutlineButton(
                          label: 'Lihat Peta',
                          icon: Icons.map_outlined,
                          onTap: onOpenMap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _HomeStats(speciesCount: dummyFloraList.length),
                    const SizedBox(height: 32),
                    Text(
                      'ALAT IDENTIFIKASI',
                      style: AppText.sectionLabel,
                    ),
                    const SizedBox(height: 12),
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: dummyFloraList.length,
                itemBuilder: (_, i) => FloraRow(item: dummyFloraList[i]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 96,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDataBadge extends StatelessWidget {
  const _LiveDataBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.emerald200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Data langsung dari 5 provinsi',
            style: AppText.monoLabel.copyWith(
              color: AppColors.emerald700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStats extends StatelessWidget {
  const _HomeStats({required this.speciesCount});

  final int speciesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBlock(value: '$speciesCount', label: 'Spesies'),
        const _StatDivider(),
        const _StatBlock(value: '12', label: 'Kawasan'),
        const _StatDivider(),
        const _StatBlock(value: '2024', label: 'Data terverifikasi'),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.homeTitle.copyWith(fontSize: 22, height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.monoLabel.copyWith(letterSpacing: 0)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.base300,
    );
  }
}

class _PortalPrimaryButton extends StatelessWidget {
  const _PortalPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryContent,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: AppColors.primaryContent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalOutlineButton extends StatelessWidget {
  const _PortalOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.base100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.base300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: AppColors.mutedGrey),
            ],
          ),
        ),
      ),
    );
  }
}
