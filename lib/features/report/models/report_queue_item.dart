enum ReportType {
  unknownImage('UNKNOWN_IMAGE'), // Untuk UC-03 (POST /unknown-images)
  endemicFinding('ENDEMIC_FINDING'); // Untuk UC-04 (POST /findings)

  final String value;
  const ReportType(this.value);

  static ReportType fromString(String val) =>
      values.firstWhere((e) => e.value == val, orElse: () => ReportType.unknownImage);
}

enum UploadStatus {
  pending('PENDING'),   // Menunggu giliran kirim
  sending('SENDING'),   // Sedang dikirim
  sent('SENT'),         // Berhasil diterima server
  failed('FAILED');     // Melewati batas 3x putaran gagal

  final String value;
  const UploadStatus(this.value);

  static UploadStatus fromString(String val) =>
      values.firstWhere((e) => e.value == val, orElse: () => UploadStatus.pending);
}

class ReportQueueItem {
  final String id; // UUID v4 dari client
  final int? historyId;
  final int? aiKey; // Diisi jika ENDEMIC_FINDING, boleh null/tebakan terbaik jika UNKNOWN_IMAGE
  final ReportType reportType;
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final UploadStatus uploadStatus;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;

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
  });

  ReportQueueItem copyWith({
    UploadStatus? uploadStatus,
    int? attemptCount,
    String? lastError,
  }) {
    return ReportQueueItem(
      id: id,
      historyId: historyId,
      aiKey: aiKey,
      reportType: reportType,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }

  // Konversi ke Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
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
    };
  }

  // Konversi dari baris SQLite ke Object Dart
  factory ReportQueueItem.fromMap(Map<String, dynamic> map) {
    return ReportQueueItem(
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
    );
  }
}