import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/flora_item.dart';

/// Satu entri indeks flora — kartu base-100 seperti daftar portal.
class FloraRow extends StatelessWidget {
  const FloraRow({super.key, required this.item});

  final FloraItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.base100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.base300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.index,
            style: AppText.monoLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.commonName,
                  style: AppText.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.scientificName,
                  style: AppText.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mutedGrey,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
