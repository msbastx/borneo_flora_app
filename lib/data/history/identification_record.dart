import 'dart:convert';

/// Satu kandidat pada hasil identifikasi, disimpan bersama riwayat supaya
/// hasilnya bisa dibuka ulang tanpa menjalankan model lagi.
class RecordCandidate {
  const RecordCandidate({
    required this.aiKey,
    required this.label,
    required this.probability,
  });

  factory RecordCandidate.fromJson(Map<String, dynamic> json) =>
      RecordCandidate(
        aiKey: json['ai_key'] as int,
        label: json['label'] as String,
        probability: (json['probability'] as num).toDouble(),
      );

  /// Indeks kelas model (sama dengan `species.ai_key`).
  final int aiKey;

  /// Label kelas dari class_names.txt.
  final String label;

  /// Rentang 0.0 sampai 1.0.
  final double probability;

  Map<String, Object> toJson() => {
        'ai_key': aiKey,
        'label': label,
        'probability': probability,
      };
}

/// Satu baris riwayat identifikasi. Bentuk [toMap] sama dengan kolom tabel
/// `identification` di schema_local_sqlite.sql, sehingga berpindah dari
/// penyimpanan sementara ke SQLite tidak mengubah model ini.
class IdentificationRecord {
  const IdentificationRecord({
    this.id,
    required this.predictedLabel,
    required this.confidence,
    required this.candidates,
    required this.imagePath,
    required this.capturedAt,
    required this.createdAt,
    this.speciesId,
    this.modelVersion,
    this.latitude,
    this.longitude,
    this.isSaved = false,
  });

  factory IdentificationRecord.fromMap(Map<String, Object?> row) {
    final List<dynamic> rawCandidates =
        jsonDecode(row['candidates_json'] as String? ?? '[]') as List<dynamic>;

    return IdentificationRecord(
      id: row['id'] as int?,
      speciesId: row['species_id'] as int?,
      predictedLabel: row['predicted_label'] as String,
      confidence: (row['confidence'] as num).toDouble(),
      candidates: [
        for (final dynamic c in rawCandidates)
          RecordCandidate.fromJson(c as Map<String, dynamic>),
      ],
      modelVersion: row['model_version'] as String?,
      imagePath: row['image_path'] as String,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(row['captured_at'] as String),
      isSaved: (row['is_saved'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Null sebelum disimpan. Repositori yang memberi nilainya.
  final int? id;

  /// Id spesies di katalog bila ada. Diisi setelah katalog memiliki id server.
  final int? speciesId;

  final String predictedLabel;

  /// Rentang 0.0 sampai 1.0.
  final double confidence;

  final List<RecordCandidate> candidates;
  final String? modelVersion;
  final String imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;

  /// Penanda tombol Simpan.
  final bool isSaved;

  final DateTime createdAt;

  IdentificationRecord copyWith({int? id, bool? isSaved}) => IdentificationRecord(
        id: id ?? this.id,
        speciesId: speciesId,
        predictedLabel: predictedLabel,
        confidence: confidence,
        candidates: candidates,
        modelVersion: modelVersion,
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
        capturedAt: capturedAt,
        isSaved: isSaved ?? this.isSaved,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'species_id': speciesId,
        'predicted_label': predictedLabel,
        'confidence': confidence,
        'candidates_json': jsonEncode([for (final c in candidates) c.toJson()]),
        'model_version': modelVersion,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': capturedAt.toUtc().toIso8601String(),
        'is_saved': isSaved ? 1 : 0,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
