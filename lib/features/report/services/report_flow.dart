import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/utils/uuid_v4.dart';
import '../../../data/models/flora_item.dart';
import '../../identification/identification_config.dart';
import '../../profile/reporter_profile.dart';
import '../models/report_queue_item.dart';
import '../repositories/report_queue_repository.dart';
import '../widgets/endemic_species_sheet.dart';
import '../widgets/report_sheet_parts.dart';
import '../widgets/unknown_species_sheet.dart';
import 'coordinate_approximator.dart';

/// Data hasil identifikasi yang dibutuhkan untuk membuat laporan.
class ReportSource {
  const ReportSource({
    required this.imagePath,
    required this.capturedAt,
    required this.aiKey,
    required this.label,
    required this.confidence,
    this.historyId,
    this.modelVersion = IdentificationConfig.modelVersion,
  });

  final String imagePath;
  final DateTime capturedAt;
  final int aiKey;

  /// Label kelas model, contoh "Shorea leprosula Miq.".
  final String label;
  final double confidence;
  final int? historyId;
  final String modelVersion;
}

/// Alur pelaporan yang dipakai layar identifikasi dan layar riwayat.
///
/// - Flora tidak dikenali: dikirim setelah pengguna menyetujui popup.
/// - Temuan endemik: dikirim setelah persetujuan, wajib dengan koordinat.
/// - Flora non-endemik: dikirim otomatis untuk dataset bila pengguna sudah
///   mengizinkannya di formulir profil.
///
/// Semua laporan masuk antrean lokal lebih dulu, lalu dikirim berurutan.
/// Notifikasi "terkirim" atau "ditolak" ditampilkan oleh `AppShell` saat
/// putaran pengiriman selesai.
class ReportFlow {
  ReportFlow({ReportQueueRepository? queue})
      : _queue = queue ?? ReportQueueRepository.instance;

  final ReportQueueRepository _queue;

  // ------------------------------------------------------------------
  // Flora tidak dikenali
  // ------------------------------------------------------------------

  Future<void> submitUnknown(
    BuildContext context,
    ReportSource source, {
    String? reasonText,
  }) async {
    final File image = File(source.imagePath);
    final bool exists = await image.exists();
    final int? size = exists ? await image.length() : null;
    if (!context.mounted) return;

    final decision = await showReportSheet(
      context,
      UnknownSpeciesSheet(
        topConfidence: source.confidence,
        threshold: IdentificationConfig.acceptanceThreshold,
        catalogCount: IdentificationConfig.classCount,
        capturedAt: source.capturedAt,
        imagePath: source.imagePath,
        imageSizeBytes: size,
        reasonText: reasonText,
        initialAllowTraining: true,
      ),
    );
    if (!context.mounted) return;
    if (!decision.send) {
      AppMessenger.show('Laporan dibatalkan. Foto tidak dikirim.');
      return;
    }
    if (!exists) {
      await _info(context, 'Citra tidak tersedia',
          'Berkas gambar tidak ditemukan. Ambil gambar kembali lalu kirim ulang.');
      return;
    }

    // Lokasi opsional untuk flora tidak dikenali.
    final coords = await tryGetLocation();
    final ReporterProfile profile = await AppPrefs.reporterProfile();
    await _enqueueAndSend(
      ReportQueueItem(
        id: generateUuidV4(),
        historyId: source.historyId,
        reportType: ReportType.unknownImage,
        imagePath: source.imagePath,
        aiKey: source.aiKey,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        createdAt: source.capturedAt,
        allowTraining: decision.allowTraining,
        confidence: source.confidence,
        modelVersion: source.modelVersion,
        reporterName: _orNull(profile.name),
        reporterEmail: _orNull(profile.email),
        reporterPhone: _orNull(profile.phone),
      ),
      note: coords == null ? 'Koordinat tidak disertakan karena lokasi tidak tersedia.' : null,
    );
  }

  // ------------------------------------------------------------------
  // Temuan endemik
  // ------------------------------------------------------------------

  Future<void> submitEndemic(
    BuildContext context,
    ReportSource source,
    FloraItem item,
  ) async {
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
      AppMessenger.show('Laporan dibatalkan. Temuan tidak dikirim.');
      return;
    }
    if (!await File(source.imagePath).exists()) {
      if (!context.mounted) return;
      await _info(context, 'Citra tidak tersedia',
          'Berkas gambar tidak ditemukan. Ambil gambar kembali lalu kirim ulang.');
      return;
    }

    // Temuan endemik tidak dikirim tanpa koordinat.
    final coords = await tryGetLocation();
    if (!context.mounted) return;
    if (coords == null) {
      await _info(
        context,
        'Lokasi diperlukan',
        'Aktifkan layanan lokasi (GPS) dan izinkan akses lokasi untuk '
            'melaporkan temuan endemik. Laporan belum dimasukkan ke antrean.',
      );
      return;
    }
    double latitude = coords.latitude;
    double longitude = coords.longitude;
    if (decision.approximateLocation) {
      final approx = CoordinateApproximator.approximate(latitude, longitude);
      latitude = approx.latitude;
      longitude = approx.longitude;
    }

    final ReporterProfile profile = await AppPrefs.reporterProfile();
    await _enqueueAndSend(ReportQueueItem(
      id: generateUuidV4(),
      historyId: source.historyId,
      reportType: ReportType.endemicFinding,
      imagePath: source.imagePath,
      aiKey: source.aiKey,
      latitude: latitude,
      longitude: longitude,
      coordinateApproximate: decision.approximateLocation,
      createdAt: source.capturedAt,
      confidence: source.confidence,
      modelVersion: source.modelVersion,
      reporterName: _orNull(profile.name),
      reporterEmail: _orNull(profile.email),
      reporterPhone: _orNull(profile.phone),
    ));
  }

  // ------------------------------------------------------------------
  // Flora non-endemik untuk dataset
  // ------------------------------------------------------------------

  /// Dipanggil otomatis setelah hasil terverifikasi sebagai non-endemik.
  ///
  /// Tidak menampilkan popup. Hanya berjalan bila pengguna mengizinkan
  /// pengiriman otomatis, dan hanya sekali untuk satu hasil identifikasi.
  /// Koordinat ikut dikirim bila izin lokasi sudah pernah diberikan.
  Future<bool> autoSubmitSighting(ReportSource source) async {
    final ReporterProfile profile = await AppPrefs.reporterProfile();
    if (!profile.datasetConsent) return false;
    return _queueSighting(source, profile, promptLocation: false, announce: true);
  }

  /// Dipanggil dari tombol pada hasil non-endemik.
  Future<void> submitSighting(BuildContext context, ReportSource source) async {
    final int? historyId = source.historyId;
    if (historyId != null &&
        await _queue.hasReportFor(historyId, ReportType.genericSighting)) {
      AppMessenger.show('Foto ini sudah ada di antrean dataset. Lihat Status Laporan.');
      return;
    }
    if (!context.mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim foto untuk dataset?'),
        content: const Text(
          'Spesies ini bukan flora endemik, jadi tidak perlu laporan temuan. '
          'Foto dapat dikirim ke server untuk memperkaya dataset pelatihan model.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Jangan kirim')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Kirim')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ReporterProfile profile = await AppPrefs.reporterProfile();
    await _queueSighting(source, profile, promptLocation: true, announce: true);
  }

  Future<bool> _queueSighting(
    ReportSource source,
    ReporterProfile profile, {
    required bool promptLocation,
    required bool announce,
  }) async {
    final int? historyId = source.historyId;
    if (historyId != null &&
        await _queue.hasReportFor(historyId, ReportType.genericSighting)) {
      return false;
    }
    if (!await File(source.imagePath).exists()) return false;

    final coords = await tryGetLocation(prompt: promptLocation);
    return _enqueueAndSend(
        ReportQueueItem(
          id: generateUuidV4(),
          historyId: historyId,
          reportType: ReportType.genericSighting,
          imagePath: source.imagePath,
          aiKey: source.aiKey,
          scientificName: source.label,
          latitude: coords?.latitude,
          longitude: coords?.longitude,
          createdAt: source.capturedAt,
          allowTraining: true,
          confidence: source.confidence,
          modelVersion: source.modelVersion,
          reporterName: _orNull(profile.name),
          reporterEmail: _orNull(profile.email),
          reporterPhone: _orNull(profile.phone),
        ),
        announce: announce,
      );
  }

  // ------------------------------------------------------------------
  // Bantuan
  // ------------------------------------------------------------------

  /// Mengembalikan false bila laporan gagal disimpan ke antrean lokal.
  Future<bool> _enqueueAndSend(
    ReportQueueItem item, {
    String? note,
    bool announce = true,
  }) async {
    try {
      await _queue.enqueue(item);
    } catch (error) {
      debugPrint('[ReportFlow] Gagal menyimpan antrean: $error');
      if (announce) AppMessenger.show('Laporan belum tersimpan: $error');
      return false;
    }
    final bool online = await _queue.hasNetwork();
    if (announce) {
      final String extra = note == null ? '' : ' $note';
      AppMessenger.show(online
          ? '${item.reportType.label} masuk antrean dan sedang dikirim...$extra'
          : 'Tidak ada jaringan. ${item.reportType.label} disimpan di antrean dan '
              'dikirim otomatis saat perangkat kembali online.$extra');
    }
    // Pengiriman berjalan di latar. Hasilnya diumumkan oleh AppShell.
    unawaited(_queue.processQueue().catchError((Object error) {
      debugPrint('[ReportFlow] Gagal memproses antrean: $error');
      return null;
    }));
    return true;
  }

  /// Lokasi perangkat saat ini, atau null bila tidak tersedia.
  ///
  /// [prompt] false: tidak meminta izin baru, hanya memakai izin yang sudah ada.
  static Future<({double latitude, double longitude})?> tryGetLocation({
    bool prompt = true,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
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
      debugPrint('[ReportFlow] Lokasi tidak tersedia: $error');
      return null;
    }
  }

  static String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();

  static Future<void> _info(BuildContext context, String title, String message) {
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
}
