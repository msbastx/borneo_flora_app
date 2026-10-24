import '../../../core/utils/uuid_v4.dart';
import '../services/coordinate_approximator.dart';
import 'report_decision.dart';

enum ReportType {
  unrecognized('unrecognized'),
  endemicFinding('endemic_finding');

  const ReportType(this.apiValue);

  /// Nilai pada kolom `report_type` dan pada body API.
  final String apiValue;
}

enum CoordinateMode { exact, approximate }

/// Laporan yang siap masuk ke tabel `report_queue`.
class ReportDraft {
  const ReportDraft({
    required this.clientUuid,
    required this.type,
    required this.imagePath,
    required this.capturedAt,
    this.speciesId,
    this.latitude,
    this.longitude,
    this.coordinateMode = CoordinateMode.exact,
    this.confidence,
    this.allowTraining = false,
    this.modelVersion,
    this.reporterName,
    this.reporterInstitution,
  });

  /// Membuat laporan dari hasil identifikasi dan pilihan pengguna.
  /// Koordinat dibulatkan di sini bila pengguna memintanya.
  factory ReportDraft.create({
    required ReportType type,
    required String imagePath,
    required DateTime capturedAt,
    required ReportDecision decision,
    int? speciesId,
    double? latitude,
    double? longitude,
    double? confidence,
    String? modelVersion,
    String? reporterName,
    String? reporterInstitution,
  }) {
    double? lat = latitude;
    double? lng = longitude;
    CoordinateMode mode = CoordinateMode.exact;

    if (decision.approximateLocation && lat != null && lng != null) {
      final ({double latitude, double longitude}) rounded =
          CoordinateApproximator.approximate(lat, lng);
      lat = rounded.latitude;
      lng = rounded.longitude;
      mode = CoordinateMode.approximate;
    }

    if (type == ReportType.endemicFinding &&
        (speciesId == null || lat == null || lng == null)) {
      throw ArgumentError('Temuan endemik wajib memiliki spesies dan koordinat.');
    }

    return ReportDraft(
      clientUuid: generateUuidV4(),
      type: type,
      imagePath: imagePath,
      capturedAt: capturedAt,
      speciesId: speciesId,
      latitude: lat,
      longitude: lng,
      coordinateMode: mode,
      confidence: confidence,
      allowTraining: type == ReportType.unrecognized && decision.allowTraining,
      modelVersion: modelVersion,
      reporterName: reporterName,
      reporterInstitution: reporterInstitution,
    );
  }

  final String clientUuid;
  final ReportType type;
  final String imagePath;
  final DateTime capturedAt;
  final int? speciesId;
  final double? latitude;
  final double? longitude;
  final CoordinateMode coordinateMode;
  final double? confidence;
  final bool allowTraining;
  final String? modelVersion;
  final String? reporterName;
  final String? reporterInstitution;

  /// Baris untuk tabel `report_queue` (lihat schema_local_sqlite.sql).
  Map<String, Object?> toRow({DateTime? now}) => {
        'client_uuid': clientUuid,
        'species_id': speciesId,
        'report_type': type.apiValue,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'coordinate_mode': coordinateMode.name,
        'confidence': confidence,
        'allow_training': allowTraining ? 1 : 0,
        'model_version': modelVersion,
        'reporter_name': reporterName,
        'reporter_institution': reporterInstitution,
        'captured_at': capturedAt.toUtc().toIso8601String(),
        'created_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      };
}
