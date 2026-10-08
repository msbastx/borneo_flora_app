import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Baris atas beranda: label aplikasi dan tombol menu.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('FLORA IDENTIFICATION', style: AppText.monoLabel),
        IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu, color: AppColors.darkGreen, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
