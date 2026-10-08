import 'dart:io';

import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/identification_source.dart';

/// Baris kontrol di bawah viewfinder: gambar mini galeri, tombol potret,
/// dan tombol balik kamera.
class CaptureControls extends StatelessWidget {
  const CaptureControls({
    super.key,
    required this.enabled,
    required this.source,
    required this.onCapture,
    required this.onOpenGallery,
    required this.onFlipCamera,
    this.recentImage,
  });

  final bool enabled;
  final IdentificationSource source;
  final File? recentImage;
  final VoidCallback onCapture;
  final VoidCallback onOpenGallery;
  final VoidCallback onFlipCamera;

  @override
  Widget build(BuildContext context) {
    final bool isCamera = source == IdentificationSource.camera;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _GalleryThumb(
          image: recentImage,
          enabled: enabled,
          onTap: onOpenGallery,
        ),
        _ShutterButton(
          enabled: enabled,
          showGalleryIcon: !isCamera,
          onTap: onCapture,
        ),
        _FlipButton(enabled: enabled && isCamera, onTap: onFlipCamera),
      ],
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({
    required this.image,
    required this.enabled,
    required this.onTap,
  });

  final File? image;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final File? image = this.image;

    return Semantics(
      button: true,
      label: 'Buka galeri',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: IdentColors.thumb,
            borderRadius: BorderRadius.circular(16),
          ),
          child: image == null
              ? Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 22,
                )
              : Image.file(
                  image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  cacheWidth: 200,
                ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.showGalleryIcon,
    required this.onTap,
  });

  final bool enabled;
  final bool showGalleryIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: showGalleryIcon ? 'Pilih dari galeri' : 'Ambil foto',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: IdentColors.lime.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: IdentColors.lime,
              ),
              child: showGalleryIcon
                  ? const Icon(
                      Icons.photo_library_outlined,
                      color: IdentColors.onLime,
                      size: 26,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipButton extends StatelessWidget {
  const _FlipButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Balik kamera',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.flip_camera_android_outlined,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.3),
            size: 28,
          ),
        ),
      ),
    );
  }
}
