import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/species_api_repository.dart';
import '../report/services/report_flow.dart';
import 'identification_controller.dart';
import 'identification_config.dart';
import 'models/identified_flora.dart';
import 'widgets/capture_view.dart';
import 'widgets/candidate_result_view.dart';
import 'widgets/unidentified_result_view.dart';
import 'widgets/result_view.dart';

class IdentificationScreen extends StatelessWidget {
  IdentificationScreen({super.key, required this.controller, ReportFlow? reports})
      : _reports = reports ?? ReportFlow();

  final IdentificationController controller;
  final ReportFlow _reports;

  ReportSource? _sourceFor(IdentifiedFlora top) {
    final image = controller.image;
    if (image == null) return null;
    return ReportSource(
      imagePath: image.path,
      capturedAt: controller.capturedAt ?? DateTime.now(),
      aiKey: top.prediction.index,
      label: top.prediction.label,
      confidence: top.prediction.probability,
      historyId: controller.currentRecordId,
    );
  }

  Future<void> _showInfo(BuildContext context, String title, String message) {
    return showDialog<void>(
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

  /// Gambar di bawah ambang penerimaan: dikirim sebagai flora tidak dikenali
  /// setelah pengguna menyetujui popup.
  Future<void> _reportUnidentified(BuildContext context) async {
    final IdentifiedFlora? top = controller.topResult;
    if (top == null) return;
    final ReportSource? source = _sourceFor(top);
    if (source == null) {
      await _showInfo(context, 'Citra tidak tersedia',
          'Pilih atau ambil gambar kembali sebelum membuat laporan.');
      return;
    }
    await _reports.submitUnknown(
      context,
      source,
      reasonText: 'Skor kandidat tertinggi ${top.prediction.percentLabel} belum melewati '
          'ambang kandidat ${(IdentificationConfig.confidenceThreshold * 100).toStringAsFixed(0)}%. '
          'Bila ini memang flora, kirimkan fotonya agar kurator dapat meninjau dan '
          'menambahkannya ke dataset.',
    );
  }

  Future<void> _handleVerification(BuildContext context, IdentifiedFlora top) async {
    // Hasil cepat atau offline ditampilkan lebih dulu. Metadata server dicari
    // lagi saat pengguna meminta verifikasi. Bila API tidak tersedia, kandidat
    // tetap bisa dilaporkan sebagai flora yang belum terverifikasi.
    if (top.item?.isVerified != true) {
      try {
        final serverItem = await SpeciesApiRepository()
            .findByAiKey(top.prediction.index)
            .timeout(const Duration(seconds: 3));
        top = IdentifiedFlora(prediction: top.prediction, item: serverItem);
      } catch (error) {
        debugPrint('[Report] Lookup metadata saat minta verifikasi gagal: $error');
      }
    }
    if (!context.mounted) return;

    final ReportSource? source = _sourceFor(top);
    if (source == null) {
      await _showInfo(context, 'Citra tidak tersedia',
          'Pilih atau ambil gambar kembali sebelum membuat laporan.');
      return;
    }

    // Laporan berbasis spesies cukup melewati ambang kandidat, karena kurator
    // tetap meninjau setiap laporan sebelum tampil di peta.
    final bool acceptedForSpeciesFlow =
        top.prediction.probability >= IdentificationConfig.confidenceThreshold &&
        top.item?.isVerified == true;

    // Skor rendah ATAU metadata server belum terverifikasi. Status endemik
    // tidak pernah disimpulkan dari label model saja.
    if (!acceptedForSpeciesFlow) {
      final String reasonText = top.prediction.probability <
              IdentificationConfig.confidenceThreshold
          ? 'Skor kandidat tertinggi ${top.prediction.percentLabel} belum melewati '
              'ambang kandidat ${(IdentificationConfig.confidenceThreshold * 100).toStringAsFixed(0)}%. '
              'Gambar bisa saja bukan flora atau spesies belum dikenali dengan cukup kuat.'
          : 'Model memberi skor ${top.prediction.percentLabel} untuk ${top.prediction.label}, '
              'tetapi metadata kelas ini belum terverifikasi di katalog server. Skor tinggi '
              'tidak membuktikan bahwa objek adalah flora; objek makanan atau benda lain juga '
              'dapat dipaksa ke salah satu dari 75 kelas model.';
      await _reports.submitUnknown(context, source, reasonText: reasonText);
      return;
    }

    final item = top.item!;
    if (!item.endemicStatusKnown) {
      await _showInfo(
        context,
        'Status endemik belum tersedia',
        'Nama spesies tersedia, tetapi status endemik/non-endemik belum '
            'diverifikasi. Aplikasi tidak akan menganggap status yang belum '
            'diketahui sebagai “bukan endemik”.',
      );
      return;
    }

    // Non-endemik: tidak perlu laporan temuan. Foto dapat dikirim untuk dataset.
    if (!item.isEndemic) {
      await _reports.submitSighting(context, source);
      return;
    }

    // Endemik terverifikasi: minta konfirmasi lalu kirim bersama koordinat.
    await _reports.submitEndemic(context, source, item);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            // Tiga tingkat: di bawah ambang kandidat -> tidak dapat diidentifikasi,
            // lolos ambang penerimaan + metadata terverifikasi -> hasil,
            // selain itu -> daftar kandidat beserta skornya.
            child: controller.showsResult
                ? (!controller.passesCandidateThreshold
                    ? UnidentifiedResultView(
                        key: const ValueKey('unidentified-result'),
                        message: 'Gambar ini bukan flora yang dapat dikenali '
                            'model (misalnya orang, benda, atau objek lain), atau '
                            'skor prediksi terlalu rendah. Identifikasi spesies '
                            'tidak tersedia.',
                        onBack: controller.reset,
                        onReport: () => _reportUnidentified(context),
                      )
                    : controller.isConfident
                    ? ResultView(
                        key: const ValueKey('verified-result'),
                        results: controller.results,
                        isConfident: true,
                        confidence: controller.confidenceLevel,
                        image: controller.image,
                        inferenceTime: controller.inferenceTime,
                        onBack: controller.reset,
                        isSaved: controller.isCurrentSaved,
                        onToggleSaved: controller.toggleSaved,
                        onRequestVerification: () async {
                          final IdentifiedFlora? top = controller.topResult;
                          if (top == null) return;
                          await _handleVerification(context, top);
                        },
                      )
                    : CandidateResultView(
                        key: const ValueKey('candidate-result'),
                        results: controller.results,
                        confidence: controller.confidenceLevel,
                        image: controller.image,
                        inferenceTime: controller.inferenceTime,
                        onBack: controller.reset,
                        onRequestVerification: () async {
                          final IdentifiedFlora? top = controller.topResult;
                          if (top == null) return;
                          await _handleVerification(context, top);
                        },
                      ))
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
