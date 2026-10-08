/// Konfigurasi model klasifikasi flora.
abstract final class IdentificationConfig {
  /// Ukuran input model (piksel, lebar dan tinggi).
  static const int inputSize = 224;

  /// Jumlah kelas yang dikenali model.
  static const int classCount = 75;

  /// Jumlah kandidat teratas yang ditampilkan.
  static const int topK = 3;

  /// Probabilitas minimum agar hasil dianggap dikenali (0.0 sampai 1.0).
  static const double confidenceThreshold = 0.6;

  /// Probabilitas minimum untuk label "Keyakinan tinggi".
  static const double highConfidenceThreshold = 0.8;

  /// Versi model yang tampil pada kartu keyakinan. Sesuaikan dengan
  /// versi model yang benar-benar dibundel.
  static const String modelVersion = 'v2.1';
}
