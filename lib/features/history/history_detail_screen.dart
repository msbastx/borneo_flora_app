import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/history/identification_record.dart';
import '../../data/species_api_repository.dart';
import '../../data/models/flora_item.dart';
import '../identification/identification_theme.dart';
import '../identification/models/confidence_level.dart';
import '../identification/identification_config.dart';
import '../identification/models/identified_flora.dart';
import '../report/services/report_flow.dart';
import '../identification/widgets/result_view.dart';
import 'history_controller.dart';

/// Membuka ulang hasil lama dan memakai jalur pelaporan antrean yang sama.
class HistoryDetailScreen extends StatelessWidget {
  HistoryDetailScreen({
    super.key,
    required this.recordId,
    required this.history,
    required this.resolve,
    ReportFlow? reports,
  }) : _reports = reports ?? ReportFlow();

  final int recordId;
  final HistoryController history;
  final RecordResolver resolve;
  final ReportFlow _reports;

  Future<void> _info(BuildContext context, String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _handleVerification(
    BuildContext context,
    IdentificationRecord record,
  ) async {
    final List<IdentifiedFlora> resolved = resolve(record);
    if (resolved.isEmpty) return;
    final IdentifiedFlora localTop = resolved.first;
    FloraItem? item = localTop.item;
    try {
      item = await SpeciesApiRepository().findByAiKey(localTop.prediction.index);
    } catch (error) {
      debugPrint('[HistoryReport] Lookup API gagal: $error');
    }
    if (!context.mounted) return;

    if (!await File(record.imagePath).exists()) {
      if (!context.mounted) return;
      await _info(context, 'Citra tidak tersedia',
          'Berkas gambar riwayat tidak ditemukan; laporan tidak dibuat.');
      return;
    }
    if (!context.mounted) return;

    final ReportSource source = ReportSource(
      imagePath: record.imagePath,
      capturedAt: record.capturedAt,
      aiKey: localTop.prediction.index,
      label: localTop.prediction.label,
      confidence: record.confidence,
      historyId: record.id ?? recordId,
      modelVersion: record.modelVersion ?? IdentificationConfig.modelVersion,
    );

    // Laporan berbasis spesies cukup melewati ambang kandidat; kurator tetap meninjaunya.
    final bool scoreAccepted =
        record.confidence >= IdentificationConfig.confidenceThreshold;

    if (scoreAccepted && item?.isVerified == true && item?.endemicStatusKnown == true) {
      if (item!.isEndemic) {
        await _reports.submitEndemic(context, source, item);
      } else {
        await _reports.submitSighting(context, source);
      }
      return;
    }

    // Metadata belum terverifikasi atau status endemik belum diketahui: kirim
    // sebagai flora yang belum dikenali agar ditinjau kurator.
    final String reason = !scoreAccepted
        ? 'Confidence hasil ini (${(record.confidence * 100).toStringAsFixed(2)}%) '
            'belum melewati ambang kandidat ${(IdentificationConfig.confidenceThreshold * 100).toStringAsFixed(0)}%. '
            'Laporan akan dikirim sebagai kandidat untuk ditinjau, bukan klaim identifikasi.'
        : item?.isVerified == true
            ? 'Status endemik untuk spesies ini belum diketahui. Citra dapat dikirim '
                'sebagai laporan yang menunggu verifikasi kurator, bukan sebagai '
                'klaim endemik yang sudah benar.'
            : 'Metadata spesies ini belum terverifikasi pada katalog server. '
                'Citra akan dikirim sebagai kandidat yang perlu diperiksa kurator.';
    await _reports.submitUnknown(context, source, reasonText: reason);
  }

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
              // Ini adalah riwayat hasil yang disimpan sebelumnya; keputusan
              // pelaporan tetap memeriksa ulang metadata server saat tombol ditekan.
              isConfident: true,
              confidence: ConfidenceLevel.fromProbability(record.confidence),
              image: File(record.imagePath),
              onBack: () => Navigator.of(context).pop(),
              isSaved: record.isSaved,
              onToggleSaved: () => history.toggleSaved(record),
              onRequestVerification: () => _handleVerification(context, record),
            );
          },
        ),
      ),
    );
  }
}
