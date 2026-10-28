import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/storage/app_database.dart';
import 'identification_history_repository.dart';
import 'identification_record.dart';

/// SQLite implementation for local identification history.
/// Candidate rows live in identification_suggestion; they are assembled into
/// the `candidates_json` shape only in memory for IdentificationRecord.fromMap.
class SqliteHistoryRepository implements IdentificationHistoryRepository {
  SqliteHistoryRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  static const String _legacyKey = 'identification_history_v1';
  static const String _migrationFlag = 'identification_history_imported_sqlite_v1';
  bool _legacyImported = false;
  Future<void>? _legacyImportInFlight;

  Future<void> _ensureLegacyImported() {
    if (_legacyImported) return Future<void>.value();
    final running = _legacyImportInFlight;
    if (running != null) return running;
    final task = _importLegacy().whenComplete(() => _legacyImportInFlight = null);
    _legacyImportInFlight = task;
    return task;
  }

  Future<void> _importLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationFlag) == true) {
      _legacyImported = true;
      return;
    }

    final raw = prefs.getString(_legacyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final rows = decoded['rows'] as List<dynamic>? ?? const <dynamic>[];
        final db = await _database.database;
        await db.transaction((txn) async {
          for (final dynamic value in rows) {
            if (value is! Map) continue;
            try {
              final record = IdentificationRecord.fromMap(
                Map<String, Object?>.from(value),
              );
              await _insertWithExecutor(txn, record);
            } catch (error) {
              debugPrint('[SqliteHistoryRepository] Lewati riwayat lama yang tidak valid: $error');
            }
          }
        });
      } catch (error) {
        debugPrint('[SqliteHistoryRepository] Import riwayat SharedPreferences gagal: $error');
        // Leave the legacy key untouched. It can be inspected/recovered later.
        return;
      }
    }

    await prefs.setBool(_migrationFlag, true);
    _legacyImported = true;
    // Keep the old key as a recovery copy; it is not read again once flagged.
  }

  @override
  Future<List<IdentificationRecord>> loadAll() async {
    await _ensureLegacyImported();
    final db = await _database.database;
    final rows = await db.query(
      'identification_history',
      orderBy: 'captured_at DESC, id DESC',
    );
    final result = <IdentificationRecord>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final suggestions = await db.query(
        'identification_suggestion',
        where: 'history_id = ?',
        whereArgs: [id],
        orderBy: 'rank ASC, id ASC',
      );
      final synthesized = Map<String, Object?>.from(row)
        ..['candidates_json'] = jsonEncode([
          for (final suggestion in suggestions)
            <String, Object?>{
              'ai_key': suggestion['ai_key'],
              'label': suggestion['label'],
              'probability': suggestion['confidence'],
            },
        ]);
      result.add(IdentificationRecord.fromMap(synthesized));
    }
    return result;
  }

  @override
  Future<IdentificationRecord> add(IdentificationRecord record) async {
    await _ensureLegacyImported();
    final db = await _database.database;
    return db.transaction((txn) => _insertWithExecutor(txn, record));
  }

  Map<String, Object?> _databaseValues(IdentificationRecord record) {
    final firstAiKey = record.candidates.isEmpty ? null : record.candidates.first.aiKey;
    return Map<String, Object?>.from(record.toMap())
      ..remove('id')
      ..remove('candidates_json')
      // Keep legacy v1 columns populated. Existing SQLite files still contain
      // NOT NULL constraints on result_status and identified_at after ALTER TABLE.
      ..['result_status'] = 'IDENTIFIED'
      ..['ai_key'] = firstAiKey
      ..['identified_at'] = record.capturedAt.toUtc().toIso8601String();
  }

  Future<IdentificationRecord> _insertWithExecutor(
    DatabaseExecutor executor,
    IdentificationRecord record,
  ) async {
    final values = _databaseValues(record);
    final id = await executor.insert('identification_history', values);
    await _insertSuggestions(executor, id, record.candidates);
    return record.copyWith(id: id);
  }

  Future<void> _insertSuggestions(
    DatabaseExecutor executor,
    int historyId,
    List<RecordCandidate> candidates,
  ) async {
    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      await executor.insert('identification_suggestion', {
        'history_id': historyId,
        'ai_key': candidate.aiKey,
        'label': candidate.label,
        'confidence': candidate.probability,
        'rank': i + 1,
      });
    }
  }

  @override
  Future<void> update(IdentificationRecord record) async {
    await _ensureLegacyImported();
    final id = record.id;
    if (id == null) return;
    final db = await _database.database;
    await db.transaction((txn) async {
      final values = _databaseValues(record);
      await txn.update(
        'identification_history',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'identification_suggestion',
        where: 'history_id = ?',
        whereArgs: [id],
      );
      await _insertSuggestions(txn, id, record.candidates);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _ensureLegacyImported();
    final db = await _database.database;
    await db.delete('identification_history', where: 'id = ?', whereArgs: [id]);
    // Foreign keys cascade suggestions and set report_queue.history_id to NULL.
  }

  @override
  Future<void> clear() async {
    await _ensureLegacyImported();
    final db = await _database.database;
    await db.delete('identification_history');
    // Deliberately keep report_queue: pending reports must survive history clear.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
    await prefs.setBool(_migrationFlag, true);
    _legacyImported = true;
  }
}
