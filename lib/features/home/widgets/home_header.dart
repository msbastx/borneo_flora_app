import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bar atas beranda — kartu branding portal, sudut membulat.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onMenuSelected});

  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.base100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.base300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borneo Biodiversity Portal',
                  style: AppText.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Kalimantan · Mobile',
                  style: AppText.monoLabel.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.base200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.base300),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: onMenuSelected,
              padding: EdgeInsets.zero,
              iconSize: 22,
              position: PopupMenuPosition.under,
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.baseContent,
              ),
              color: AppColors.base100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.base300),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'guide',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.menu_book_outlined),
                    title: Text('Panduan penggunaan'),
                  ),
                ),
                PopupMenuItem(
                  value: 'history',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history),
                    title: Text('Riwayat identifikasi'),
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Pengaturan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
