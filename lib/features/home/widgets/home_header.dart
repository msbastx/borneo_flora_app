import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Baris atas beranda: label aplikasi dan tombol menu.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onMenuSelected});

  final ValueChanged<String>? onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('FLORA IDENTIFICATION', style: AppText.monoLabel),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: onMenuSelected,
          icon: const Icon(Icons.menu, color: AppColors.darkGreen, size: 28),
          color: const Color(0xFFFAF5FA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ],
    );
  }
}
