import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/report/report_config.dart';
import 'identification_history_repository.dart';
import 'identification_record.dart';

/// Penyimpanan sementara di shared_preferences, dipakai sampai SQLite siap.
/// Cukup untuk ratusan baris metadata. Gambar tidak disimpan di sini, hanya
/// path-nya.
class PrefsHistoryRepository implements IdentificationHistoryRepository {
  PrefsHistoryRepository({this.maxRecords = defaultMaxRecords});

  /// Batas jumlah baris. Yang terlama dan belum disimpan dibuang lebih dulu,
  /// baris bertanda Simpan tidak pernah dibuang otomatis.
  static const int defaultMaxRecords = 200;

  static const String _key = 'identification_history_v1';

  final int maxRecords;

  /// Antrean agar baca-ubah-tulis tidak saling menimpa.
  Future<void> _tail = Future<void>.value();

  Future<T> _run<T>(Future<T> Function() action) {
    final Future<T> result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<_Store> _read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return _Store(1, []);

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> rows = json['rows'] as List<dynamic>? ?? const [];
      return _Store(
        json['next_id'] as int? ?? 1,
        [
          for (final dynamic r in rows)
            IdentificationRecord.fromMap(r as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      // Data rusak: mulai dari kosong daripada membuat layar macet.
      debugPrint('Riwayat rusak, direset: $e');
      return _Store(1, []);
    }
  }

  Future<void> _write(_Store store) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'next_id': store.nextId,
        'rows': [for (final r in store.rows) r.toMap()],
      }),
    );
  }

  void _trim(List<IdentificationRecord> rows) {
    rows.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    while (rows.length > maxRecords) {
      final int i = rows.lastIndexWhere((r) => !r.isSaved);
      if (i < 0) break;
      rows.removeAt(i);
    }
  }

  @override
  Future<List<IdentificationRecord>> loadAll() => _run(() async {
        final List<IdentificationRecord> rows = (await _read()).rows;
        rows.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        return rows;
      });

  @override
  Future<IdentificationRecord> add(IdentificationRecord record) =>
      _run(() async {
        final _Store store = await _read();
        final IdentificationRecord stored = record.copyWith(id: store.nextId);
        store.nextId += 1;
        store.rows.add(stored);
        _trim(store.rows);
        await _write(store);
        return stored;
      });

  @override
  Future<void> update(IdentificationRecord record) => _run(() async {
        final _Store store = await _read();
        final int i = store.rows.indexWhere((r) => r.id == record.id);
        if (i < 0) return;
        store.rows[i] = record;
        await _write(store);
      });

  @override
  Future<void> delete(int id) => _run(() async {
        final _Store store = await _read();
        store.rows.removeWhere((r) => r.id == id);
        await _write(store);
      });

  @override
  Future<void> clear() => _run(() async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      });

  Dio get dioInstance => Dio(BaseOptions(baseUrl: ReportConfig.apiBaseUrl));
}

class _Store {
  _Store(this.nextId, this.rows);

  int nextId;
  final List<IdentificationRecord> rows;
}
