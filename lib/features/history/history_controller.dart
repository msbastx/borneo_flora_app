import 'package:flutter/foundation.dart';

import '../../data/history/identification_history_repository.dart';
import '../../data/history/identification_record.dart';
import '../identification/models/identified_flora.dart';

/// Memasangkan satu baris riwayat dengan data katalog.
typedef RecordResolver = List<IdentifiedFlora> Function(
  IdentificationRecord record,
);

enum HistoryFilter {
  all('SEMUA'),
  saved('TERSIMPAN');

  const HistoryFilter(this.label);

  final String label;
}

/// State layar riwayat: daftar, filter, dan statistik. Perubahan dilakukan
/// secara optimistis (daftar langsung berubah, penyimpanan menyusul) supaya
/// geser-untuk-hapus tidak menyisakan baris yang sudah dibuang.
class HistoryController extends ChangeNotifier {
  HistoryController(this._repository);

  final IdentificationHistoryRepository _repository;

  List<IdentificationRecord> _all = const [];
  HistoryFilter _filter = HistoryFilter.all;
  bool _loading = true;
  bool _disposed = false;

  bool get isLoading => _loading;
  HistoryFilter get filter => _filter;
  bool get isEmpty => _all.isEmpty;

  List<IdentificationRecord> get visible => switch (_filter) {
        HistoryFilter.all => _all,
        HistoryFilter.saved => _all.where((r) => r.isSaved).toList(),
      };

  int get total => _all.length;
  int get savedCount => _all.where((r) => r.isSaved).length;

  /// Jumlah spesies berbeda yang pernah dikenali.
  int get speciesCount => _all.map((r) => r.predictedLabel).toSet().length;

  IdentificationRecord? byId(int id) {
    for (final IdentificationRecord r in _all) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await _repository.loadAll();
    } catch (e) {
      debugPrint('Gagal memuat riwayat: $e');
      _all = const [];
    }
    _loading = false;
    notifyListeners();
  }

  void setFilter(HistoryFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> toggleSaved(IdentificationRecord record) async {
    final IdentificationRecord next = record.copyWith(isSaved: !record.isSaved);
    _all = [for (final r in _all) r.id == next.id ? next : r];
    notifyListeners();
    try {
      await _repository.update(next);
    } catch (e) {
      debugPrint('Gagal menyimpan penanda: $e');
      await load();
    }
  }

  Future<void> delete(IdentificationRecord record) async {
    final int? id = record.id;
    if (id == null) return;
    _all = _all.where((r) => r.id != id).toList();
    notifyListeners();
    try {
      await _repository.delete(id);
    } catch (e) {
      debugPrint('Gagal menghapus riwayat: $e');
      await load();
    }
  }

  /// Mengembalikan baris yang baru dihapus (tombol Urungkan). Id-nya baru.
  Future<void> restore(IdentificationRecord record) async {
    try {
      await _repository.add(record);
    } catch (e) {
      debugPrint('Gagal memulihkan riwayat: $e');
    }
    await load();
  }

  Future<void> clear() async {
    _all = const [];
    notifyListeners();
    try {
      await _repository.clear();
    } catch (e) {
      debugPrint('Gagal mengosongkan riwayat: $e');
      await load();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
