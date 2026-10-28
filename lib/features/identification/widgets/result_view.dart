import 'dart:io';

import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/confidence_level.dart';
import '../models/identified_flora.dart';
import 'candidate_list.dart';
import 'result_actions.dart';
import 'result_header.dart';
import 'species_info_tabs.dart';

/// Tahap 2: hasil identifikasi. Menerima data langsung (bukan controller)
/// supaya tampilannya tetap utuh saat animasi pergantian layar berjalan.
class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.results,
    required this.isConfident,
    required this.confidence,
    required this.onBack,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onRequestVerification,
    this.image,
    this.inferenceTime,
  });

  final List<IdentifiedFlora> results;
  final bool isConfident;
  final ConfidenceLevel confidence;
  final File? image;
  final Duration? inferenceTime;
  final VoidCallback onBack;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onRequestVerification;

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature belum tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = MediaQuery.paddingOf(context);
    final IdentifiedFlora top = results.first;
    final List<IdentifiedFlora> candidates = results.skip(1).take(3).toList();

    return ColoredBox(
      color: IdentColors.cream,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ResultHeader(
                  top: top,
                  isConfident: isConfident,
                  confidence: confidence,
                  image: image,
                  inferenceTime: inferenceTime,
                  onBack: onBack,
                  onShare: () => _comingSoon(context, 'Bagikan'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResultActions(
                        isSaved: isSaved,
                        onToggleSaved: onToggleSaved,
                        onRequestVerification: onRequestVerification,
                        showSave: isConfident,
                      ),
                      const SizedBox(height: 24),
                      if (candidates.isNotEmpty)
                        CandidateList(
                          candidates: candidates,
                          title: isConfident
                              ? 'KANDIDAT LAIN'
                              : 'KANDIDAT TERDEKAT',
                        ),
                      if (isConfident) ...[
                        const SizedBox(height: 20),
                        SpeciesInfoTabs(flora: top),
                      ],
                    ],
                  ),
                ),
              ),
              // Ruang untuk navbar melayang.
              SliverToBoxAdapter(child: SizedBox(height: inset.bottom + 16)),
            ],
          ),
          // Menjaga area status bar tetap gelap saat konten digulir.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: inset.top,
            child: const ColoredBox(color: IdentColors.background),
          ),
        ],
      ),
    );
  }
}
