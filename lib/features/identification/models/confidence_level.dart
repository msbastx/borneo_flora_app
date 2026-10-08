import '../identification_config.dart';

/// Tingkat keyakinan hasil, diturunkan dari probabilitas teratas.
enum ConfidenceLevel {
  high('KEYAKINAN TINGGI'),
  medium('KEYAKINAN SEDANG'),
  low('KEYAKINAN RENDAH');

  const ConfidenceLevel(this.label);

  final String label;

  static ConfidenceLevel fromProbability(double probability) {
    if (probability >= IdentificationConfig.highConfidenceThreshold) {
      return ConfidenceLevel.high;
    }
    if (probability >= IdentificationConfig.confidenceThreshold) {
      return ConfidenceLevel.medium;
    }
    return ConfidenceLevel.low;
  }
}
