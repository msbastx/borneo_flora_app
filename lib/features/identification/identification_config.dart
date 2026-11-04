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

  /// Pengali logit yang sama dengan `FixedLogitScaleModel(scale=0.3)` pada
  /// portal Django (`apps/identifier/services.py`).
  ///
  /// Aset `.ptl` hasil ekspor sudah memuat pengali ini di dalam graph, jadi
  /// nilainya 1.0. Nilai ini hanya jadi pengaman bila aset dimuat tanpa
  /// wrapper: logit mentah membuat softmax terlalu tajam sehingga gambar
  /// non-flora ikut lolos ambang penerimaan.
  static const double logitScale = 1.0;

  /// Ambang penerimaan hasil, sama dengan `best_threshold` di portal
  /// (`identifier/services.py`). Di bawah ambang ini hasil dianggap
  /// "tidak dapat diidentifikasi".
  static const String _acceptanceThresholdText = String.fromEnvironment(
    'FLORA_ACCEPTANCE_THRESHOLD',
    defaultValue: '0.9929907321929932',
  );
  static final double acceptanceThreshold =
      double.tryParse(_acceptanceThresholdText) ?? 0.9929907321929932;

  /// Sama dengan `best_threshold` di portal (`identifier/services.py`).
  static const double portalBestMatchThreshold = 0.9929907321929932;

  /// Versi model yang tampil pada kartu keyakinan. Sesuaikan dengan
  /// versi model yang benar-benar dibundel.
  static const String modelVersion = 'v2.1';
}
