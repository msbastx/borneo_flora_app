import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../identification_config.dart';
import '../identification_theme.dart';
import '../models/confidence_level.dart';
import 'progress_bar.dart';

/// Kartu "Tingkat keyakinan": angka besar, batang progres, dan catatan.
class ConfidenceCard extends StatelessWidget {
  const ConfidenceCard({
    super.key,
    required this.percentNumber,
    required this.probability,
    required this.level,
    required this.note,
    this.inferenceTime,
  });

  final String percentNumber;
  final double probability;
  final ConfidenceLevel level;
  final String note;
  final Duration? inferenceTime;

  String get _modelLine {
    final Duration? time = inferenceTime;
    final String version = 'MODEL ${IdentificationConfig.modelVersion}';
    if (time == null) return version;
    final String seconds = formatDecimal(time.inMilliseconds / 1000);
    return '$version · $seconds DETIK';
  }

  @override
  Widget build(BuildContext context) {
    final Color accent =
        level == ConfidenceLevel.low ? IdentColors.amber : IdentColors.lime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: IdentColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TINGKAT KEYAKINAN', style: IdentText.label(size: 9.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: percentNumber,
                  style: IdentText.body(
                    size: 44,
                    color: accent,
                    weight: FontWeight.w800,
                    height: 1,
                  ),
                  children: [
                    TextSpan(
                      text: '%',
                      style: IdentText.body(
                        size: 22,
                        color: accent,
                        weight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    level.label,
                    style: IdentText.label(
                      color: accent,
                      size: 10,
                      weight: FontWeight.w700,
                      spacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_modelLine, style: IdentText.label(size: 9, spacing: 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(
            value: probability,
            fillColor: accent,
            trackColor: const Color(0xFF3F4C44),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: IdentColors.mutedOnDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: IdentText.body(
                    size: 11.5,
                    color: IdentColors.bodyOnDark,
                    height: 1.45,
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
