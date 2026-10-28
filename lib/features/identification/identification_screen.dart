import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/utils/uuid_v4.dart';
import '../../data/species_api_repository.dart';
import 'identification_controller.dart';
import 'identification_config.dart';
import 'models/identified_flora.dart';
import '../report/report_config.dart';
import '../report/services/coordinate_approximator.dart';
import '../report/widgets/unknown_species_sheet.dart';
import '../report/widgets/endemic_species_sheet.dart';
import '../report/widgets/report_sheet_parts.dart';
import '../report/models/report_queue_item.dart';
import '../report/repositories/report_queue_repository.dart';
import 'widgets/capture_view.dart';
import 'widgets/candidate_result_view.dart';
import 'widgets/result_view.dart';

class IdentificationScreen extends StatelessWidget {
  const IdentificationScreen({super.key, required this.controller});

  final IdentificationController controller;

  ReportQueueRepository _newQueueRepository() => ReportQueueRepository(
        dio: Dio(
          BaseOptions(
            // apiBaseUrl berakhir dengan /api/v1/. Endpoint repo tidak diawali slash.
            baseUrl: ReportConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ),
      );

  Future<({double latitude, double longitude})?> _tryGetLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (error) {
      debugPrint('[Report] Gagal memperoleh koordinat: $error');
      return null;
    }
  }

  Future<ReportQueueItem?> _enqueueAndSync(ReportQueueItem item) async {
    final ReportQueueRepository queue = _newQueueRepository();
    await queue.enqueue(item);
    await queue.processQueue();
    return queue.getItemById(item.id);
  }

  void _showQueueStatus(
    BuildContext context,
    ReportQueueItem? item, {
    required String reportName,
    bool noCoordinates = false,
  }) {
    if (!context.mounted) return;
    final String message;
    if (item?.uploadStatus == UploadStatus.sent) {
      message = '$reportName diterima server.';
    } else if (item?.uploadStatus == UploadStatus.failed) {
      message = 'Laporan tersimpan tetapi ditolak server: ${item?.lastError ?? "periksa data laporan"}';
    } else {
      message = 'Laporan disimpan dalam antrean dan akan dicoba lagi saat jaringan tersedia.'
          '${noCoordinates ? " Koordinat tidak disertakan karena izin/lokasi tidak tersedia." : ""}';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerification(BuildContext context, IdentifiedFlora top) async {
    final imageFile = controller.image;

    // Ensure a fast/offline prediction can render immediately, then resolve
    // its metadata on demand when the user requests verification. If the API
    // is unavailable, the candidate remains reportable as unverified.
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

    final bool acceptedForSpeciesFlow =
        top.prediction.probability >= IdentificationConfig.acceptanceThreshold &&
        top.item?.isVerified == true;

    // Candidate state: low model score OR missing/unverified server metadata.
    // Never infer a species' endemic status from a model label alone.
    if (!acceptedForSpeciesFlow) {
      final int? imageSize = imageFile != null && await imageFile.exists()
          ? await imageFile.length()
          : null;
      if (!context.mounted) return;
      final String reasonText = top.prediction.probability <
              IdentificationConfig.acceptanceThreshold
          ? 'Skor kandidat tertinggi ${top.prediction.percentLabel} belum melewati '
              'ambang penerimaan ${(IdentificationConfig.acceptanceThreshold * 100).toStringAsFixed(2)}%. '
              'Gambar bisa saja bukan flora atau spesies belum dikenali dengan cukup kuat.'
          : 'Model memberi skor ${top.prediction.percentLabel} untuk ${top.prediction.label}, '
              'tetapi metadata kelas ini belum terverifikasi di katalog server. Skor tinggi '
              'tidak membuktikan bahwa objek adalah flora; objek makanan atau benda lain juga '
              'dapat dipaksa ke salah satu dari 75 kelas model.';
      final decision = await showReportSheet(
        context,
        UnknownSpeciesSheet(
          topConfidence: top.prediction.probability,
          threshold: IdentificationConfig.acceptanceThreshold,
          catalogCount: IdentificationConfig.classCount,
          capturedAt: DateTime.now(),
          imagePath: imageFile?.path,
          imageSizeBytes: imageSize,
          reasonText: reasonText,
        ),
      );
      if (!context.mounted) return;

      if (!decision.send) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan dibatalkan.')),
        );
        return;
      }
      if (imageFile == null || !await imageFile.exists()) {
        await _showInfo(context,
            title: 'Citra tidak tersedia',
            message: 'Pilih atau ambil gambar kembali sebelum membuat laporan.');
        return;
      }

      // Lokasi opsional untuk laporan citra tidak dikenal.
      final coords = await _tryGetLocation();
      if (!context.mounted) return;
      try {
        final ReportQueueItem item = ReportQueueItem(
          id: generateUuidV4(),
          historyId: controller.currentRecordId,
          reportType: ReportType.unknownImage,
          imagePath: imageFile.path,
          aiKey: top.prediction.index,
          latitude: coords?.latitude,
          longitude: coords?.longitude,
          createdAt: DateTime.now(),
          allowTraining: decision.allowTraining,
          confidence: top.prediction.probability,
          modelVersion: IdentificationConfig.modelVersion,
        );
        final queued = await _enqueueAndSync(item);
        _showQueueStatus(
          context,
          queued,
          reportName: 'Laporan flora yang belum dikenali',
          noCoordinates: coords == null,
        );
      } catch (error) {
        debugPrint('[Report] Gagal menyimpan antrean: $error');
        await _showInfo(
          context,
          title: 'Laporan belum tersimpan',
          message: 'Gagal menyimpan laporan ke antrean lokal: $error',
        );
      }
      return;
    }

    final item = top.item!;
    if (!item.endemicStatusKnown) {
      await _showInfo(
        context,
        title: 'Status endemik belum tersedia',
        message: 'Nama spesies tersedia, tetapi status endemik/non-endemik '
            'belum diverifikasi. Aplikasi tidak akan menganggap status yang '
            'belum diketahui sebagai “bukan endemik”.',
      );
      return;
    }

    // Kasus B: katalog secara eksplisit menyatakan status diketahui dan bukan endemik.
    if (!item.isEndemic) {
      await _showInfo(
        context,
        title: 'Tidak memenuhi kriteria laporan endemik',
        message: '${top.prediction.label} memiliki metadata katalog terverifikasi '
            'sebagai non-endemik. Karena itu, laporan “temuan flora endemik di '
            'luar kawasan konservasi” tidak dikirim.',
      );
      return;
    }

    // Kasus C: spesies terverifikasi sebagai endemik -> minta konfirmasi pengguna.
    final decision = await showReportSheet(
      context,
      EndemicSpeciesSheet(
        commonName: item.commonName,
        scientificName: item.scientificName,
        iucnStatus: item.iucnCode,
        isProtected: item.isProtected,
        imageUrl: item.imageUrl,
      ),
    );
    if (!context.mounted) return;
    if (!decision.send) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan dibatalkan.')),
      );
      return;
    }
    if (imageFile == null || !await imageFile.exists()) {
      await _showInfo(context,
          title: 'Citra tidak tersedia',
          message: 'Pilih atau ambil gambar kembali sebelum membuat laporan.');
      return;
    }

    // Laporan temuan membutuhkan lokasi. Jangan mengirim klaim lokasi kosong.
    final rawCoords = await _tryGetLocation();
    if (!context.mounted) return;
    if (rawCoords == null) {
      await _showInfo(
        context,
        title: 'Lokasi diperlukan',
        message: 'Aktifkan layanan lokasi dan izinkan akses lokasi untuk '
            'melaporkan temuan endemik. Laporan belum dimasukkan ke antrean.',
      );
      return;
    }

    double latitude = rawCoords.latitude;
    double longitude = rawCoords.longitude;
    if (decision.approximateLocation) {
      final approx = CoordinateApproximator.approximate(latitude, longitude);
      latitude = approx.latitude;
      longitude = approx.longitude;
    }

    try {
      final ReportQueueItem queueItem = ReportQueueItem(
        id: generateUuidV4(),
        historyId: controller.currentRecordId,
        reportType: ReportType.endemicFinding,
        imagePath: imageFile.path,
        aiKey: top.prediction.index,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
        confidence: top.prediction.probability,
        modelVersion: IdentificationConfig.modelVersion,
        coordinateApproximate: decision.approximateLocation,
      );
      final queued = await _enqueueAndSync(queueItem);
      _showQueueStatus(context, queued, reportName: 'Laporan temuan flora endemik');
    } catch (error) {
      debugPrint('[Report] Gagal menyimpan antrean endemik: $error');
      _showInfo(
        context,
        title: 'Laporan belum tersimpan',
        message: 'Antrean laporan gagal disimpan: $error',
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
                ? (controller.isConfident
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
