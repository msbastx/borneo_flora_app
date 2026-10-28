import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/flora_repository.dart';
import '../../data/models/flora_item.dart';
import '../../data/species_api_repository.dart';
import '../../data/history/identification_history_repository.dart';
import '../../data/history/identification_record.dart';
import '../../data/history/sqlite_history_repository.dart';
import 'identification_config.dart';
import 'models/confidence_level.dart';
import 'models/flora_prediction.dart';
import 'models/identification_source.dart';
import 'models/identification_status.dart';
import 'models/identified_flora.dart';
import 'services/flora_classifier.dart';

/// Mengatur state dan alur identifikasi. Layar cukup mendengarkan
/// controller ini dan memanggil method publiknya.
class IdentificationController extends ChangeNotifier {
  IdentificationController({
    FloraClassifier? classifier,
    ImagePicker? picker,
    FloraRepository? repository,
    SpeciesApiRepository? speciesApiRepository,
    IdentificationHistoryRepository? history,
  })  : _classifier = classifier ?? FloraClassifier(),
        _picker = picker ?? ImagePicker(),
        _repository = repository ?? FloraRepository(),
        _speciesApiRepository = speciesApiRepository ?? SpeciesApiRepository(),
        _history = history ?? SqliteHistoryRepository();

  final FloraClassifier _classifier;
  final ImagePicker _picker;
  final FloraRepository _repository;
  final SpeciesApiRepository _speciesApiRepository;
  final IdentificationHistoryRepository _history;

  IdentificationStatus _status = IdentificationStatus.loadingModel;
  IdentificationSource _source = IdentificationSource.camera;
  CameraDevice _cameraDevice = CameraDevice.rear;
  File? _image;
  File? _recentImage;
  List<IdentifiedFlora> _results = const [];
  Duration? _inferenceTime;
  IdentificationRecord? _record;
  String? _errorMessage;
  bool _loadStarted = false;
  bool _disposed = false;
  int _identifyGeneration = 0;

  IdentificationStatus get status => _status;

  /// Riwayat dipakai bersama layar Riwayat.
  IdentificationHistoryRepository get history => _history;

  /// Apakah hasil yang sedang tampil sudah ditandai Simpan.
  bool get isCurrentSaved => _record?.isSaved ?? false;
  IdentificationSource get source => _source;
  CameraDevice get cameraDevice => _cameraDevice;

  /// Gambar yang sedang diproses atau sedang ditampilkan pada hasil.
  File? get image => _image;

  /// Gambar terakhir yang dipilih, untuk gambar mini di samping tombol potret.
  File? get recentImage => _recentImage;

  List<IdentifiedFlora> get results => _results;
  Duration? get inferenceTime => _inferenceTime;
  String? get errorMessage => _errorMessage;

  /// Tombol ambil gambar aktif bila model siap dan tidak sedang memproses.
  bool get canPick =>
      _classifier.isLoaded && _status != IdentificationStatus.predicting;

  /// Layar hasil tampil bila ada prediksi yang selesai.
  bool get showsResult =>
      _status == IdentificationStatus.success && _results.isNotEmpty;

  IdentifiedFlora? get topResult => _results.isEmpty ? null : _results.first;

  ConfidenceLevel get confidenceLevel {
    final IdentifiedFlora? top = topResult;
    return top == null
        ? ConfidenceLevel.low
        : ConfidenceLevel.fromProbability(top.prediction.probability);
  }

  /// Model melewati ambang confidence yang dipakai untuk penerimaan awal.
  bool get passesAcceptanceThreshold =>
      (topResult?.prediction.probability ?? 0) >=
      IdentificationConfig.acceptanceThreshold;

  /// Sistem hanya menyebut hasil teridentifikasi bila skor model melewati
  /// ambang DAN katalog memiliki metadata yang diverifikasi.
  /// Metadata fallback/placeholder tidak boleh menentukan status endemik.
  bool get isConfident =>
      passesAcceptanceThreshold && topResult?.item?.isVerified == true;

  String get recognitionIssue {
    final top = topResult;
    if (top == null) return 'Model belum menghasilkan kandidat flora.';
    if (!passesAcceptanceThreshold) {
      final percent = (IdentificationConfig.acceptanceThreshold * 100).toStringAsFixed(2);
      return 'Skor kandidat tertinggi ${top.prediction.percentLabel} belum melewati ambang penerimaan ${percent}%. Gambar mungkin bukan flora atau prediksi model belum cukup kuat.';
    }
    if (top.item?.isVerified != true) {
      return 'Model memprediksi ${top.prediction.label} dengan skor ${top.prediction.percentLabel}, tetapi metadata spesies belum diverifikasi pada katalog server. Skor tinggi tidak membuktikan gambar adalah flora; objek non-flora juga dapat memperoleh skor tinggi. Hasil ini tetap kandidat, bukan identifikasi final.';
    }
    return 'Status spesies belum dapat dipastikan.';
  }

  int? get currentRecordId => _record?.id;

  /// Memulihkan satu baris riwayat menjadi daftar hasil yang siap ditampilkan.
  List<IdentifiedFlora> resolveRecord(IdentificationRecord record) {
    final List<RecordCandidate> candidates = record.candidates.isEmpty
        ? [
            RecordCandidate(
              aiKey: -1,
              label: record.predictedLabel,
              probability: record.confidence,
            ),
          ]
        : record.candidates;

    return [
      for (final RecordCandidate c in candidates)
        IdentifiedFlora(
          prediction: FloraPrediction(
            index: c.aiKey,
            label: c.label,
            probability: c.probability,
            logit: 0,
          ),
          item: _repository.findByScientificName(c.label),
        ),
    ];
  }

  /// Tombol Simpan pada layar hasil.
  Future<void> toggleSaved() async {
    final IdentificationRecord? current = _record;
    if (current == null) return;

    final IdentificationRecord next = current.copyWith(isSaved: !current.isSaved);
    _record = next;
    notifyListeners();
    try {
      await _history.update(next);
    } catch (e) {
      debugPrint('Gagal menyimpan penanda: $e');
      _record = current;
      notifyListeners();
    }
  }

  /// Aman dipanggil berulang. Model hanya dimuat sekali.
  Future<void> loadModel() async {
    if (_loadStarted) return;
    _loadStarted = true;
    _setStatus(IdentificationStatus.loadingModel);
    try {
      await _repository.ensureLoadedFromAssets();
      await _classifier.load();
      _setStatus(IdentificationStatus.ready);
    } catch (e) {
      debugPrint('Gagal memuat model: $e');
      _loadStarted = false; // izinkan coba lagi saat tab dibuka ulang
      _fail('Model gagal dimuat. Mulai ulang aplikasi, lalu coba lagi.');
    }
  }

  void setSource(IdentificationSource source) {
    if (_source == source) return;
    _source = source;
    notifyListeners();
  }

  /// Berganti antara kamera belakang dan depan.
  void flipCamera() {
    _cameraDevice = _cameraDevice == CameraDevice.rear
        ? CameraDevice.front
        : CameraDevice.rear;
    notifyListeners();
  }

  /// Aksi tombol potret, mengikuti sumber yang dipilih.
  Future<void> capture() => _source == IdentificationSource.camera
      ? identifyFromCamera()
      : identifyFromGallery();

  Future<void> identifyFromCamera() => _identify(ImageSource.camera);

  Future<void> identifyFromGallery() => _identify(ImageSource.gallery);

  /// Kembali dari layar hasil ke layar pengambilan citra.
  void reset() {
    if (_status == IdentificationStatus.predicting) return;
    _identifyGeneration++;
    _image = null;
    _results = const [];
    _inferenceTime = null;
    _record = null;
    _errorMessage = null;
    _setStatus(_classifier.isLoaded
        ? IdentificationStatus.ready
        : IdentificationStatus.loadingModel);
  }

  Future<void> _identify(ImageSource source) async {
    if (!canPick) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: _cameraDevice,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (picked == null) return;

      final DateTime capturedAt = DateTime.now();
      final int generation = ++_identifyGeneration;
      _image = File(picked.path);
      _recentImage = _image;
      _results = const [];
      _inferenceTime = null;
      _record = null;
      _errorMessage = null;
      _setStatus(IdentificationStatus.predicting);

      final Stopwatch watch = Stopwatch()..start();
      final List<FloraPrediction> predictions =
          await _classifier.classify(_image!, topK: IdentificationConfig.topK);
      watch.stop();
      if (_disposed || generation != _identifyGeneration) return;

      _inferenceTime = watch.elapsed;
      // Render hasil model segera dari class_names.txt. Inferensi dan tampilan
      // kandidat tidak menunggu jaringan maupun API katalog.
      _results = [
        for (final FloraPrediction prediction in predictions)
          IdentifiedFlora(
            prediction: prediction,
            item: _repository.findByScientificName(prediction.label),
          ),
      ];
      // Riwayat lokal ditulis untuk setiap inferensi, termasuk mode kandidat,
      // supaya laporan offline bisa ditautkan ke history_id tanpa server.
      _record = await _recordResult(capturedAt);
      if (_disposed || generation != _identifyGeneration) return;
      _setStatus(IdentificationStatus.success);

      // Metadata server hanya memperkaya hasil secara asinkron. Jika offline,
      // halaman kandidat tetap dapat dipakai dan laporan tetap dapat diantrekan.
      unawaited(_enrichResults(predictions, capturedAt, generation));
    } on ClassificationException catch (e) {
      _fail(e.message);
    } catch (e) {
      debugPrint('Error saat identifikasi: $e');
      _fail('Gagal memproses gambar');
    }
  }

  Future<IdentifiedFlora> _resolvePrediction(
    FloraPrediction prediction,
  ) async {
    FloraItem? item;
    try {
      item = await _speciesApiRepository
          .findByAiKey(prediction.index)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint(
        'Lookup API gagal untuk ai_key=${prediction.index}; memakai katalog lokal: $e',
      );
    }

    item ??= _repository.findByScientificName(prediction.label);
    return IdentifiedFlora(prediction: prediction, item: item);
  }

  Future<void> _enrichResults(
    List<FloraPrediction> predictions,
    DateTime capturedAt,
    int generation,
  ) async {
    final enriched = await Future.wait<IdentifiedFlora>([
      for (final prediction in predictions) _resolvePrediction(prediction),
    ]);
    if (_disposed || generation != _identifyGeneration ||
        _status != IdentificationStatus.success) {
      return;
    }

    _results = enriched;
    if (isConfident && _record == null) {
      _record = await _recordResult(capturedAt);
      if (_disposed || generation != _identifyGeneration) return;
    }
    notifyListeners();
  }

  Future<IdentificationRecord?> _recordResult(DateTime capturedAt) async {
    final IdentifiedFlora top = _results.first;
    try {
      return await _history.add(
        IdentificationRecord(
          speciesId: top.item?.serverId,
          predictedLabel: top.prediction.label,
          confidence: top.prediction.probability,
          candidates: [
            for (final IdentifiedFlora r in _results)
              RecordCandidate(
                aiKey: r.prediction.index,
                label: r.prediction.label,
                probability: r.prediction.probability,
              ),
          ],
          modelVersion: IdentificationConfig.modelVersion,
          imagePath: _image!.path,
          capturedAt: capturedAt,
          createdAt: capturedAt,
        ),
      );
    } catch (e) {
      debugPrint('Gagal merekam riwayat: $e');
      return null;
    }
  }

  void _fail(String message) {
    _errorMessage = message;
    _setStatus(IdentificationStatus.failure);
  }

  void _setStatus(IdentificationStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // Proses asinkron bisa selesai setelah layar ditutup.
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _identifyGeneration++;
    super.dispose();
  }
}
