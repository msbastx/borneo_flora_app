import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Judul bagian "INDEKS FLORA" beserta jumlah dan garis pemisah.
class FloraIndexHeader extends StatelessWidget {
  const FloraIndexHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('INDEKS FLORA', style: AppText.monoLabel),
            Text(
              '$count →',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
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
