/// Konfigurasi model klasifikasi flora.
abstract final class IdentificationConfig {
  /// Ukuran input model (piksel, lebar dan tinggi).
  static const int inputSize = 224;

  /// Jumlah kelas yang dikenali model.
  static const int classCount = 75;

  /// Jumlah kandidat teratas yang ditampilkan.
  static const int topK = 4;

  /// Probabilitas minimum agar hasil dianggap dikenali (0.0 sampai 1.0).
  static const double confidenceThreshold = 0.45;

  /// Probabilitas minimum untuk label "Keyakinan tinggi" di kartu UI.
  static const double highConfidenceThreshold = 0.75;

  /// Ambang awal development untuk menghindari penerimaan skor rendah.
  /// Kalibrasikan dengan kumpulan uji flora dan non-flora sebelum digunakan
  /// sebagai angka final. Softmax tinggi tidak membuktikan gambar adalah flora.
  static const String _acceptanceThresholdText = String.fromEnvironment(
    'FLORA_ACCEPTANCE_THRESHOLD',
    defaultValue: '0.95',
  );
  static final double acceptanceThreshold =
      double.tryParse(_acceptanceThresholdText) ?? 0.95;

  /// Versi model yang tampil pada kartu keyakinan. Sesuaikan dengan
  /// versi model yang benar-benar dibundel.
  static const String modelVersion = 'v2.1';
}
