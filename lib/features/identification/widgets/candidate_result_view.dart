import 'dart:io';

import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/confidence_level.dart';
import '../models/identified_flora.dart';
import 'candidate_list.dart';
import 'result_actions.dart';
import 'result_header.dart';

/// Separate candidate screen used when the model score or species metadata
/// is not sufficient to present a verified flora identification.
class CandidateResultView extends StatelessWidget {
  const CandidateResultView({
    super.key,
    required this.results,
    required this.confidence,
    required this.onBack,
    required this.onRequestVerification,
    this.image,
    this.inferenceTime,
  });

  final List<IdentifiedFlora> results;
  final ConfidenceLevel confidence;
  final File? image;
  final Duration? inferenceTime;
  final VoidCallback onBack;
  final VoidCallback onRequestVerification;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(child: Text('Belum ada kandidat identifikasi.'));
    }

    final EdgeInsets inset = MediaQuery.paddingOf(context);
    final IdentifiedFlora top = results.first;
    final List<IdentifiedFlora> otherCandidates = results.skip(1).take(3).toList();

    return ColoredBox(
      color: IdentColors.cream,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ResultHeader(
                  top: top,
                  isConfident: false,
                  confidence: confidence,
                  image: image,
                  inferenceTime: inferenceTime,
                  onBack: onBack,
                  onShare: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bagikan belum tersedia.')),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4C77D)),
                        ),
                        child: const Text(
                          'Ini adalah kandidat teratas dari 75 kelas flora, bukan konfirmasi bahwa gambar merupakan tanaman. Gambar makanan, orang, atau objek lain juga dapat menghasilkan skor tinggi pada model klasifikasi tertutup.',
                          style: TextStyle(
                            color: Color(0xFF59451B),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ResultActions(
                        isSaved: false,
                        onToggleSaved: () {},
                        onRequestVerification: onRequestVerification,
                        showSave: false,
                      ),
                      if (otherCandidates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        CandidateList(
                          candidates: otherCandidates,
                          title: '3 KANDIDAT FLORA LAIN',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: inset.bottom + 96),
              ),
            ],
          ),
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
