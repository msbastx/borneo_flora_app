import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'identification_controller.dart';
import 'identification_config.dart';
import 'models/identified_flora.dart';
import '../report/report_config.dart';
import '../report/widgets/unknown_species_sheet.dart';
import '../report/widgets/endemic_species_sheet.dart';
import '../report/widgets/report_sheet_parts.dart';
import '../report/models/report_queue_item.dart';
import '../report/repositories/report_queue_repository.dart';
import 'widgets/capture_view.dart';
import 'widgets/result_view.dart';

class IdentificationScreen extends StatelessWidget {
  const IdentificationScreen({super.key, required this.controller});

  final IdentificationController controller;

  Future<void> _handleVerification(BuildContext context, IdentifiedFlora top) async {
    final imageFile = controller.image;
    final dio = Dio(BaseOptions(baseUrl: ReportConfig.apiBaseUrl));

    // KONDISI 1: Jika model tidak yakin (skrip di bawah confidenceThreshold)
    if (!controller.isConfident) {
      final decision = await showReportSheet(
        context,
        UnknownSpeciesSheet(
          topConfidence: top.prediction.probability,
          threshold: IdentificationConfig.confidenceThreshold,
          catalogCount: 75,
          capturedAt: DateTime.now(),
          imagePath: imageFile?.path,
          imageSizeBytes: imageFile == null ? null : await imageFile.length(),
        ),
      );
      if (!context.mounted) return;

      if (decision.send && imageFile != null) {
        try {
          final queueItem = ReportQueueItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            reportType: ReportType.unknownImage,
            imagePath: imageFile.path,
            aiKey: top.prediction.index,
            createdAt: DateTime.now(),
          );
          await ReportQueueRepository(dio: dio).enqueue(queueItem);
          await ReportQueueRepository(dio: dio).processQueue();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan flora tidak dikenal berhasil dikirim ke server.')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim ke server, disimpan ke antrean offline: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan dibatalkan.')),
        );
      }
      return;
    }

    // KONDISI 2 & 3: Model Yakin (isConfident == true) -> Cek apakah Endemik
    final bool isEndemic = top.item?.isEndemic ?? false;

    if (!isEndemic) {
      // BUKAN ENDEMIK: Tampilkan popup informasi
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verifikasi Spesies'),
          content: Text(
            '${top.prediction.label} teridentifikasi sebagai flora biasa / bukan spesies endemik di luar kawasan konservasi, sehingga tidak memerlukan pelaporan temuan khusus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // ADALAH ENDEMIK: Munculkan sheet EndemicSpeciesSheet
    final decision = await showReportSheet(
      context,
      EndemicSpeciesSheet(
        commonName: top.item?.commonName ?? top.prediction.label,
        scientificName: top.prediction.label,
        iucnStatus: top.item?.iucnCode ?? 'NE',
        isProtected: top.item?.isProtected ?? false,
        imageUrl: top.item?.imageUrl,
      ),
    );
    if (!context.mounted) return;

    if (decision.send && imageFile != null) {
      try {
        final queueItem = ReportQueueItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          reportType: ReportType.endemicFinding,
          imagePath: imageFile.path,
          aiKey: top.prediction.index,
          createdAt: DateTime.now(),
        );
        await ReportQueueRepository(dio: dio).enqueue(queueItem);
        await ReportQueueRepository(dio: dio).processQueue();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan temuan flora endemik berhasil dikirim ke server.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim ke server, disimpan ke antrean offline: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan dibatalkan.')),
      );
    }
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
                await _handleVerification(context, top);
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