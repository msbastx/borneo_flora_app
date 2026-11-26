import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Judul bagian "INDEKS FLORA" beserta jumlah dan garis pemisah.
class FloraIndexHeader extends StatelessWidget {
  const FloraIndexHeader({super.key, required this.count, this.onTap});

  final int count;

  /// Membuka daftar lengkap. Null berarti angka tidak dapat diketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('INDEKS FLORA', style: AppText.monoLabel),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  onTap == null ? '$count →' : 'Lihat semua $count →',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: AppColors.divider, thickness: 1),
      ],
    );
  }
}
