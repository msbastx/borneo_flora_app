enum ReportType {
  unknownImage('UNKNOWN_IMAGE'),
  endemicFinding('ENDEMIC_FINDING');

  final String value;
  const ReportType(this.value);

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
  });

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
      );

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
      );
}
