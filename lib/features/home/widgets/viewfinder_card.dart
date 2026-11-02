import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Kartu identifikasi — gaya kartu portal (base-100, border, shadow).
class ViewfinderCard extends StatelessWidget {
  const ViewfinderCard({
    super.key,
    required this.onCapture,
    required this.onGallery,
  });

  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.base100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.base300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.center_focus_strong_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identifikasi spesies',
                      style: AppText.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ambil foto atau pilih dari galeri untuk klasifikasi flora.',
                      style: AppText.homeSubtitle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Potret & identifikasi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryContent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.base200,
                  foregroundColor: AppColors.baseContent,
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.base300),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
