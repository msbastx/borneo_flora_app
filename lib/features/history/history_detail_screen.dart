import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/utils/uuid_v4.dart';
import '../../data/history/identification_record.dart';
import '../../data/species_api_repository.dart';
import '../../data/models/flora_item.dart';
import '../identification/identification_theme.dart';
import '../identification/models/confidence_level.dart';
import '../identification/identification_config.dart';
import '../identification/models/identified_flora.dart';
import '../report/models/report_queue_item.dart';
import '../report/report_config.dart';
import '../report/repositories/report_queue_repository.dart';
import '../report/services/coordinate_approximator.dart';
import '../report/widgets/unknown_species_sheet.dart';
import '../report/widgets/endemic_species_sheet.dart';
import '../report/widgets/report_sheet_parts.dart';
import '../identification/widgets/result_view.dart';
import 'history_controller.dart';

/// Membuka ulang hasil lama dan memakai jalur pelaporan antrean yang sama.
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

  ReportQueueRepository _queueRepository() => ReportQueueRepository(
        dio: Dio(BaseOptions(
          baseUrl: ReportConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        )),
      );

  Future<({double latitude, double longitude})?> _tryGetLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (error) {
      debugPrint('[HistoryReport] Lokasi tidak tersedia: $error');
      return null;
    }
  }

  Future<ReportQueueItem?> _enqueueAndSync(ReportQueueItem item) async {
    final queue = _queueRepository();
    await queue.enqueue(item);
    await queue.processQueue();
    return queue.getItemById(item.id);
  }

  void _showStatus(BuildContext context, ReportQueueItem? item, String type,
      {bool noCoordinates = false}) {
    if (!context.mounted) return;
    final String message;
    if (item?.uploadStatus == UploadStatus.sent) {
      message = '$type diterima server untuk ditinjau kurator.';
    } else if (item?.uploadStatus == UploadStatus.failed) {
      message = 'Laporan ditolak server: ${item?.lastError ?? "periksa data"}';
    } else {
      message = 'Laporan disimpan dalam antrean dan akan dicoba lagi saat jaringan tersedia.'
          '${noCoordinates ? " Koordinat tidak tersedia sehingga tidak disertakan." : ""}';
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
      final FloraItem apiItem = await SpeciesApiRepository()
          .findByAiKey(localTop.prediction.index);
      item = apiItem;
    } catch (error) {
      debugPrint('[HistoryReport] Lookup API gagal: $error');
    }
    if (!context.mounted) return;
    final IdentifiedFlora top = IdentifiedFlora(
      prediction: localTop.prediction,
      item: item,
    );
    final File image = File(record.imagePath);
    final bool imageExists = await image.exists();
    final int? imageSize = imageExists ? await image.length() : null;
    if (!context.mounted) return;

    final bool scoreAccepted =
        record.confidence >= IdentificationConfig.acceptanceThreshold;

    if (scoreAccepted && item?.isVerified == true && item?.endemicStatusKnown == true) {
      if (item?.isEndemic != true) {
        await _info(
          context,
          'Tidak memenuhi kriteria laporan endemik',
          '${top.prediction.label} tercatat sebagai non-endemik pada metadata '
              'yang terverifikasi. Laporan temuan endemik tidak dikirim.',
        );
        return;
      }

      final decision = await showReportSheet(
        context,
        EndemicSpeciesSheet(
          commonName: item!.commonName,
          scientificName: item.scientificName,
          iucnStatus: item.iucnCode,
          isProtected: item.isProtected,
          imageUrl: item.imageUrl,
        ),
      );
      if (!context.mounted) return;
      if (!decision.send) return;
      if (!imageExists) {
        await _info(context, 'Citra tidak tersedia',
            'Berkas gambar riwayat tidak ditemukan; laporan tidak dibuat.');
        return;
      }
      final coords = await _tryGetLocation();
      if (!context.mounted) return;
      if (coords == null) {
        await _info(context, 'Lokasi diperlukan',
            'Aktifkan layanan lokasi dan izinkan akses lokasi untuk melaporkan temuan endemik.');
        return;
      }
      double latitude = coords.latitude;
      double longitude = coords.longitude;
      if (decision.approximateLocation) {
        final approximate = CoordinateApproximator.approximate(latitude, longitude);
        latitude = approximate.latitude;
        longitude = approximate.longitude;
      }
      try {
        final queued = await _enqueueAndSync(ReportQueueItem(
          id: generateUuidV4(),
          historyId: record.id ?? recordId,
          aiKey: top.prediction.index,
          reportType: ReportType.endemicFinding,
          imagePath: record.imagePath,
          latitude: latitude,
          longitude: longitude,
          coordinateApproximate: decision.approximateLocation,
          confidence: record.confidence,
          modelVersion: record.modelVersion,
          createdAt: record.capturedAt,
        ));
        _showStatus(context, queued, 'Laporan temuan endemik');
      } catch (error) {
        await _info(context, 'Antrean laporan gagal', error.toString());
      }
      return;
    }

    // Jika belum ada metadata terverifikasi atau status endemik belum diketahui,
    // izinkan pengguna mengirimnya sebagai laporan belum dikenali untuk kurator.
    final String reason = !scoreAccepted
        ? 'Confidence hasil ini (${(record.confidence * 100).toStringAsFixed(2)}%) '
            'belum melewati ambang ${(IdentificationConfig.acceptanceThreshold * 100).toStringAsFixed(2)}%. '
            'Laporan akan dikirim sebagai kandidat untuk ditinjau, bukan klaim identifikasi.'
        : item?.isVerified == true
            ? 'Status endemik untuk spesies ini belum diketahui. Citra dapat dikirim '
                'sebagai laporan yang menunggu verifikasi kurator, bukan sebagai '
                'klaim endemik yang sudah benar.'
            : 'Metadata spesies ini belum terverifikasi pada katalog server. '
                'Citra akan dikirim sebagai kandidat yang perlu diperiksa kurator.';
    final decision = await showReportSheet(
      context,
      UnknownSpeciesSheet(
        topConfidence: record.confidence,
        threshold: IdentificationConfig.acceptanceThreshold,
        catalogCount: IdentificationConfig.classCount,
        capturedAt: record.capturedAt,
        imagePath: record.imagePath,
        imageSizeBytes: imageSize,
        latitude: record.latitude,
        longitude: record.longitude,
        reasonText: reason,
      ),
    );
    if (!context.mounted) return;
    if (!decision.send) return;
    if (!imageExists) {
      await _info(context, 'Citra tidak tersedia',
          'Berkas gambar riwayat tidak ditemukan; laporan tidak dibuat.');
      return;
    }
    final coords = await _tryGetLocation();
    if (!context.mounted) return;
    try {
      final queued = await _enqueueAndSync(ReportQueueItem(
        id: generateUuidV4(),
        historyId: record.id ?? recordId,
        aiKey: top.prediction.index,
        reportType: ReportType.unknownImage,
        imagePath: record.imagePath,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        allowTraining: decision.allowTraining,
        confidence: record.confidence,
        modelVersion: record.modelVersion,
        createdAt: record.capturedAt,
      ));
      _showStatus(context, queued, 'Laporan flora belum terverifikasi',
          noCoordinates: coords == null);
    } catch (error) {
      await _info(context, 'Antrean laporan gagal', error.toString());
    }
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
