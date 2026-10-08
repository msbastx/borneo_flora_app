import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Kartu viewfinder dengan tombol potret dan galeri.
/// Aksi navigasi diberikan dari luar lewat [onCapture] dan [onGallery].
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
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          const _CornerBracket(alignment: Alignment.topLeft),
          const _CornerBracket(alignment: Alignment.topRight),
          const _CornerBracket(alignment: Alignment.bottomLeft),
          const _CornerBracket(alignment: Alignment.bottomRight),
          const Positioned(
            top: 24,
            left: 2,
            child: Text(
              'VIEWFINDER',
              style: TextStyle(
                color: AppColors.sage,
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CaptureButton(onTap: onCapture),
                const SizedBox(width: 10),
                _GalleryButton(onTap: onGallery),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neonLime,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              'Potret & Identifikasi',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Siku bingkai di salah satu sudut kartu.
class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.alignment});

  final Alignment alignment;

  static const BorderSide _side =
      BorderSide(color: AppColors.cornerBracket, width: 2);

  @override
  Widget build(BuildContext context) {
    final bool isTop = alignment.y < 0;
    final bool isLeft = alignment.x < 0;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            border: Border(
              top: isTop ? _side : BorderSide.none,
              bottom: !isTop ? _side : BorderSide.none,
              left: isLeft ? _side : BorderSide.none,
              right: !isLeft ? _side : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
