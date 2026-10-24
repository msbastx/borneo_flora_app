import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

import '../../../core/constants/app_assets.dart';
import '../identification_config.dart';
import '../models/flora_prediction.dart';

/// Kesalahan yang aman ditampilkan langsung kepada pengguna.
class ClassificationException implements Exception {
  const ClassificationException(this.message);

  final String message;

  @override
  String toString() => 'ClassificationException: $message';
}

/// Membungkus model PyTorch Lite. Tidak mengenal widget sama sekali.
class FloraClassifier {
  ClassificationModel? _model;
  List<String> _labels = const [];

  bool get isLoaded => _model != null;

  /// Memuat model dan daftar nama kelas satu kali saja.
  Future<void> load() async {
    if (isLoaded) return;
    _labels = await _loadLabels();
    _model = await PytorchLite.loadClassificationModel(
      AppAssets.floraModel,
      IdentificationConfig.inputSize,
      IdentificationConfig.inputSize,
      IdentificationConfig.classCount,
      labelPath: AppAssets.classNames,
    );
    debugPrint('Model berhasil dimuat');
  }

  /// Mengembalikan [topK] prediksi dengan probabilitas tertinggi.
  Future<List<FloraPrediction>> classify(
    File image, {
    int topK = IdentificationConfig.topK,
  }) async {
    final ClassificationModel? model = _model;
    if (model == null) {
      throw const ClassificationException('Model belum dimuat');
    }

    final imageBytes = await image.readAsBytes();
    final List<dynamic>? raw = await model.getImagePredictionList(imageBytes);
    if (raw == null || raw.isEmpty) {
      throw const ClassificationException('Model gagal memproses output');
    }

    final List<double> logits =
        raw.map((e) => double.parse(e.toString())).toList();

    // Development diagnostics: getImagePredictionList returns raw model scores.
    // These logs help determine whether those values look like logits or
    // probabilities and whether label/output dimensions agree.
    final double rawMin = logits.reduce(min);
    final double rawMax = logits.reduce(max);
    final double rawSum = logits.fold(0.0, (sum, value) => sum + value);
    debugPrint(
      '[FloraClassifier] outputCount=${logits.length}, '
      'labelCount=${_labels.length}, rawMin=${rawMin.toStringAsFixed(5)}, '
      'rawMax=${rawMax.toStringAsFixed(5)}, '
      'rawSum=${rawSum.toStringAsFixed(5)}',
    );

    if (logits.length != _labels.length) {
      throw ClassificationException(
        'Jumlah output model (${logits.length}) tidak sama dengan '
        'jumlah label (${_labels.length}). Periksa model dan class_names.txt.',
      );
    }

    final List<double> probabilities = softmax(logits);

    final List<int> debugOrder = List<int>.generate(probabilities.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    for (final int index in debugOrder.take(5)) {
      debugPrint(
        '[FloraClassifier] top index=$index label="${_labels[index]}" '
        'raw=${logits[index].toStringAsFixed(5)} '
        'softmax=${probabilities[index].toStringAsFixed(5)}',
      );
    }

    final List<FloraPrediction> predictions = List.generate(
      probabilities.length,
      (i) => FloraPrediction(
        index: i,
        label: _labels[i],
        probability: probabilities[i],
        logit: logits[i],
      ),
    );
    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return predictions.take(topK).toList();
  }

  /// Mengubah logit menjadi probabilitas. Dikurangi nilai maksimum
  /// agar perhitungan eksponen stabil.
  @visibleForTesting
  static List<double> softmax(List<double> logits) {
    final double maxLogit = logits.reduce(max);
    final List<double> exps = logits.map((l) => exp(l - maxLogit)).toList();
    final double sum = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  Future<List<String>> _loadLabels() async {
    final String raw = await rootBundle.loadString(AppAssets.classNames);
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
