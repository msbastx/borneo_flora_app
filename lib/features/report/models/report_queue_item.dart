/// Jenis laporan yang dikirim aplikasi ke server.
///
/// [endpoint] adalah path baru yang ikut menyimpan identitas pelapor.
/// [legacyEndpoint] adalah path lama, dipakai bila server belum diperbarui.
enum ReportType {
  unknownImage('UNKNOWN_IMAGE', 'reports/unknown-images/', 'unknown-images/',
      'Laporan flora tidak dikenali'),
  endemicFinding('ENDEMIC_FINDING', 'reports/findings/', 'findings/',
      'Laporan temuan flora endemik'),
  genericSighting('GENERIC_SIGHTING', 'reports/sightings/', 'sightings/',
      'Foto flora untuk dataset');

  final String value;
  final String endpoint;
  final String legacyEndpoint;
  final String label;
  const ReportType(this.value, this.endpoint, this.legacyEndpoint, this.label);

  static ReportType fromString(String val) =>
      values.firstWhere((e) => e.value == val, orElse: () => ReportType.unknownImage);
}

enum UploadStatus {
  pending('PENDING'),
  sending('SENDING'),
  sent('SENT'),
  failed('FAILED');

  final String value;
  const UploadStatus(this.value);

  static UploadStatus fromString(String val) =>
      values.firstWhere((e) => e.value == val, orElse: () => UploadStatus.pending);
}

class ReportQueueItem {
  final String id;
  final int? historyId;
  final int? aiKey;
  final ReportType reportType;
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final UploadStatus uploadStatus;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final bool allowTraining;
  final double? confidence;
  final String? modelVersion;
  final bool coordinateApproximate;

  /// Label model, dipakai server untuk mencocokkan spesies pada laporan dataset.
  final String? scientificName;

  /// Diisi dari formulir profil saat laporan dibuat.
  final String? reporterName;
  final String? reporterEmail;

  const ReportQueueItem({
    required this.id,
    this.historyId,
    this.aiKey,
    required this.reportType,
    required this.imagePath,
    this.latitude,
    this.longitude,
    this.uploadStatus = UploadStatus.pending,
    this.attemptCount = 0,
    this.lastError,
    required this.createdAt,
    this.allowTraining = false,
    this.confidence,
    this.modelVersion,
    this.coordinateApproximate = false,
    this.scientificName,
    this.reporterName,
    this.reporterEmail,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  ReportQueueItem copyWith({
    String? imagePath,
    UploadStatus? uploadStatus,
    int? attemptCount,
    String? lastError,
  }) => ReportQueueItem(
        id: id,
        historyId: historyId,
        aiKey: aiKey,
        reportType: reportType,
        imagePath: imagePath ?? this.imagePath,
        latitude: latitude,
        longitude: longitude,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError,
        createdAt: createdAt,
        allowTraining: allowTraining,
        confidence: confidence,
        modelVersion: modelVersion,
        coordinateApproximate: coordinateApproximate,
        scientificName: scientificName,
        reporterName: reporterName,
        reporterEmail: reporterEmail,
      );

  /// Kolom teks untuk permintaan multipart (tanpa berkas citra).
  ///
  /// [includeReporter] false dipakai saat mengirim ke endpoint lama, yang
  /// belum mengenal kolom identitas pelapor.
  Map<String, String> formFields({bool includeReporter = true}) {
    final Map<String, String> fields = {
      'client_id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'allow_training': allowTraining ? 'true' : 'false',
      'coordinate_approximate': coordinateApproximate ? 'true' : 'false',
    };
    void put(String key, Object? value) {
      if (value == null) return;
      final String text = value.toString().trim();
      if (text.isNotEmpty) fields[key] = text;
    }

    put('ai_key', aiKey);
    if (hasCoordinates) {
      put('latitude', latitude);
      put('longitude', longitude);
    }
    put('confidence', confidence);
    put('model_version', modelVersion);
    if (reportType == ReportType.genericSighting) {
      put('scientific_name', scientificName);
    }
    if (includeReporter) {
      put('reporter_name', reporterName);
      put('reporter_email', reporterEmail);
    }
    return fields;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'history_id': historyId,
        'ai_key': aiKey,
        'report_type': reportType.value,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'upload_status': uploadStatus.value,
        'attempt_count': attemptCount,
        'last_error': lastError,
        'created_at': createdAt.toIso8601String(),
        'allow_training': allowTraining ? 1 : 0,
        'confidence': confidence,
        'model_version': modelVersion,
        'coordinate_approximate': coordinateApproximate ? 1 : 0,
        'scientific_name': scientificName,
        'reporter_name': reporterName,
        'reporter_email': reporterEmail,
      };

  factory ReportQueueItem.fromMap(Map<String, dynamic> map) => ReportQueueItem(
        id: map['id'] as String,
        historyId: map['history_id'] as int?,
        aiKey: map['ai_key'] as int?,
        reportType: ReportType.fromString(map['report_type'] as String),
        imagePath: map['image_path'] as String,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        uploadStatus: UploadStatus.fromString(map['upload_status'] as String),
        attemptCount: map['attempt_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        allowTraining: (map['allow_training'] as int? ?? 0) == 1,
        confidence: (map['confidence'] as num?)?.toDouble(),
        modelVersion: map['model_version'] as String?,
        coordinateApproximate: (map['coordinate_approximate'] as int? ?? 0) == 1,
        scientificName: map['scientific_name'] as String?,
        reporterName: map['reporter_name'] as String?,
        reporterEmail: map['reporter_email'] as String?,
      );
}
