import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'identification_controller.dart';
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
