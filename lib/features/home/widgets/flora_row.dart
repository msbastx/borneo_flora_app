import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/flora_item.dart';

/// Satu baris pada daftar indeks flora.
class FloraRow extends StatelessWidget {
  const FloraRow({super.key, required this.item});

  final FloraItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.index,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.mutedGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.commonName,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.scientificName,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, thickness: 1, height: 1),
      ],
    );
  }
}
