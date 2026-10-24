import 'package:flutter/material.dart';

import '../../guide/capture_guide_screen.dart';
import '../../history/history_screen.dart';
import '../identification_controller.dart';
import '../identification_theme.dart';
import 'capture_controls.dart';
import 'source_toggle.dart';
import 'viewfinder_panel.dart';

/// Tahap 1: arahkan kamera atau pilih dari galeri.
class CaptureView extends StatelessWidget {
  const CaptureView({super.key, required this.controller});

  final IdentificationController controller;

  void _openGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CaptureGuideScreen(
          onFinish: () => Navigator.of(ctx).pop(),
          onSkip: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          repository: controller.history,
          resolve: controller.resolveRecord,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Saat navbar melayang di shell, padding bawah sudah memuat tingginya.
    final EdgeInsets inset = MediaQuery.paddingOf(context);

    return ColoredBox(
      color: IdentColors.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, inset.top + 12, 20, inset.bottom + 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('IDENTIFIKASI FLORA', style: IdentText.label()),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _openHistory(context),
                      tooltip: 'Riwayat identifikasi',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _openGuide(context),
                      tooltip: 'Panduan pengambilan citra',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Arahkan ke\ndaun atau bunga',
              style: IdentText.serif(size: 30),
            ),
            const SizedBox(height: 18),
            SourceToggle(
              source: controller.source,
              onChanged: controller.setSource,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ViewfinderPanel(
                source: controller.source,
                status: controller.status,
                image: controller.image,
                errorMessage: controller.errorMessage,
              ),
            ),
            const SizedBox(height: 18),
            CaptureControls(
              enabled: controller.canPick,
              source: controller.source,
              recentImage: controller.recentImage,
              onCapture: controller.capture,
              onOpenGallery: controller.identifyFromGallery,
              onFlipCamera: controller.flipCamera,
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
