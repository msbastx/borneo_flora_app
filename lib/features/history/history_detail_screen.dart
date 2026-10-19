import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/history/identification_record.dart';
import '../identification/identification_theme.dart';
import '../identification/models/confidence_level.dart';
import '../identification/widgets/result_view.dart';
import 'history_controller.dart';

/// Membuka ulang hasil lama memakai tampilan hasil yang sama dengan layar
/// Identifikasi. Hasil dipulihkan dari data tersimpan, model tidak dijalankan lagi.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    super.key,
    required this.recordId,
    required this.history,
    required this.resolve,
  });

  final int recordId;
  final HistoryController history;
  final RecordResolver resolve;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IdentColors.cream,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListenableBuilder(
          listenable: history,
          builder: (context, _) {
            final IdentificationRecord? record = history.byId(recordId);
            if (record == null) return const SizedBox.shrink();

            return ResultView(
              results: resolve(record),
              // Hanya hasil yang dikenali yang direkam ke riwayat.
              isConfident: true,
              confidence: ConfidenceLevel.fromProbability(record.confidence),
              image: File(record.imagePath),
              onBack: () => Navigator.of(context).pop(),
              isSaved: record.isSaved,
              onToggleSaved: () => history.toggleSaved(record),
            );
          },
        ),
      ),
    );
  }
}
