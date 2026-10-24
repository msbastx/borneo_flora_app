import '../../../core/utils/format.dart';

/// Satu hasil prediksi untuk satu kelas flora.
class FloraPrediction {
  const FloraPrediction({
    required this.index,
    required this.label,
    required this.probability,
    required this.logit,
  });

  final int index;
  final String label;

  /// Probabilitas hasil softmax, rentang 0.0 sampai 1.0.
  final double probability;

  /// Skor mentah dari model sebelum softmax.
  final double logit;

  double get percent => probability * 100;

  /// Angka saja dengan koma desimal, contoh "82,3".
  String get percentNumber => formatDecimal(percent);

  /// Contoh "82,3%".
  String get percentLabel => '$percentNumber%';
}
