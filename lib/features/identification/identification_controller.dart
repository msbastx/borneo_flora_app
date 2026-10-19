import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/flora_repository.dart';
import '../../data/history/identification_history_repository.dart';
import '../../data/history/identification_record.dart';
import '../../data/history/prefs_history_repository.dart';
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
    IdentificationHistoryRepository? history,
  })  : _classifier = classifier ?? FloraClassifier(),
        _picker = picker ?? ImagePicker(),
        _repository = repository ?? FloraRepository(),
        _history = history ?? PrefsHistoryRepository();

  final FloraClassifier _classifier;
  final ImagePicker _picker;
  final FloraRepository _repository;
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

  /// Hasil dianggap dikenali bila probabilitas teratas melewati ambang.
  bool get isConfident => confidenceLevel != ConfidenceLevel.low;

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
      );
      if (picked == null) return;

      final DateTime capturedAt = DateTime.now();
      _image = File(picked.path);
      _recentImage = _image;
      _results = const [];
      _inferenceTime = null;
      _errorMessage = null;
      _setStatus(IdentificationStatus.predicting);

      final Stopwatch watch = Stopwatch()..start();
      final List<FloraPrediction> predictions =
          await _classifier.classify(_image!, topK: IdentificationConfig.topK);
      watch.stop();

      _inferenceTime = watch.elapsed;
      _results = [
        for (final FloraPrediction p in predictions)
          IdentifiedFlora(
            prediction: p,
            item: _repository.findByScientificName(p.label),
          ),
      ];
      // Hanya hasil yang dikenali yang masuk riwayat. Citra yang tidak dikenali
      // tidak disimpan, sesuai teks pada popup "tidak dikenali".
      _record = (_results.isNotEmpty && isConfident)
          ? await _recordResult(capturedAt)
          : null;
      _setStatus(IdentificationStatus.success);
    } on ClassificationException catch (e) {
      _fail(e.message);
    } catch (e) {
      debugPrint('Error saat identifikasi: $e');
      _fail('Gagal memproses gambar');
    }
  }

  Future<IdentificationRecord?> _recordResult(DateTime capturedAt) async {
    final IdentifiedFlora top = _results.first;
    try {
      return await _history.add(
        IdentificationRecord(
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
    super.dispose();
  }
}
