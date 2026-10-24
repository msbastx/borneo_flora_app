import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'identification_controller.dart';
import 'identification_config.dart';
import 'models/identified_flora.dart';
import '../report/widgets/unknown_species_sheet.dart';
import '../report/widgets/report_sheet_parts.dart';
import 'widgets/capture_view.dart';
import 'widgets/result_view.dart';

class IdentificationScreen extends StatelessWidget {
  const IdentificationScreen({super.key, required this.controller});

  final IdentificationController controller;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: controller.showsResult
                ? ResultView(
                    key: const ValueKey('result'),
                    results: controller.results,
                    isConfident: controller.isConfident,
                    confidence: controller.confidenceLevel,
                    image: controller.image,
                    inferenceTime: controller.inferenceTime,
                    onBack: controller.reset,
                    isSaved: controller.isCurrentSaved,
                    onToggleSaved: controller.toggleSaved,
                    onRequestVerification: () async {
                      final IdentifiedFlora? top = controller.topResult;
                      if (top == null) return;
                      final decision = await showReportSheet(
                        context,
                        UnknownSpeciesSheet(
                          topConfidence: top.prediction.probability,
                          threshold: IdentificationConfig.confidenceThreshold,
                          catalogCount: 75,
                          capturedAt: DateTime.now(),
                          imagePath: controller.image?.path,
                          imageSizeBytes: controller.image == null
                              ? null
                              : await controller.image!.length(),
                        ),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              decision.send
                                  ? 'Pilihan laporan dicatat, tetapi pengiriman ke server belum diimplementasikan.'
                                  : 'Laporan dibatalkan.',
                            ),
                          ),
                        );
                    },
                  )
                : CaptureView(
                    key: const ValueKey('capture'),
                    controller: controller,
                  ),
          );
        },
      ),
    );
  }
}
