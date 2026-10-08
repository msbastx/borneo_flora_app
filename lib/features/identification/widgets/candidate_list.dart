import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/identified_flora.dart';
import 'progress_bar.dart';

/// Daftar kandidat lain beserta persentase dan batang keyakinan.
class CandidateList extends StatelessWidget {
  const CandidateList({
    super.key,
    required this.candidates,
    this.title = 'KANDIDAT LAIN',
  });

  final List<IdentifiedFlora> candidates;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: IdentText.label(color: IdentColors.mutedOnLight)),
        const SizedBox(height: 10),
        const Divider(color: IdentColors.hairline, thickness: 1, height: 1),
        for (final IdentifiedFlora c in candidates) _CandidateRow(flora: c),
      ],
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.flora});

  final IdentifiedFlora flora;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: IdentColors.placeholderTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_florist_outlined,
                  size: 20,
                  color: IdentColors.green.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flora.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: IdentText.serif(
                        size: 17,
                        color: IdentColors.green,
                        height: 1.2,
                      ),
                    ),
                    if (flora.showsScientificName) ...[
                      const SizedBox(height: 2),
                      Text(
                        flora.scientificName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: IdentText.body(
                          size: 12,
                          color: IdentColors.mutedOnLight,
                          style: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ProgressBar(
                      value: flora.prediction.probability,
                      height: 4,
                      fillColor: IdentColors.green,
                      trackColor: IdentColors.barTrack,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 52,
                child: Text(
                  flora.prediction.percentLabel,
                  textAlign: TextAlign.right,
                  style: IdentText.label(
                    color: IdentColors.green,
                    size: 12,
                    weight: FontWeight.w700,
                    spacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: IdentColors.hairline, thickness: 1, height: 1),
      ],
    );
  }
}
