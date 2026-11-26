import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../models/report_queue_item.dart';
import '../report_config.dart';
import '../services/dio_report_sender.dart';
import '../services/queue_runner.dart';

/// Antrean laporan offline (store-and-forward) di atas tabel `report_queue`.
///
/// Pakai [ReportQueueRepository.instance] di seluruh aplikasi agar hanya ada
/// satu antrean dan satu putaran pengiriman. Setiap putaran yang selesai
/// diumumkan lewat [results], dan dipakai `AppShell` untuk notifikasi.
class ReportQueueRepository implements ReportQueueStore {
  ReportQueueRepository({
    AppDatabase? dbHelper,
    required Dio dio,
    ReportSender? sender,
    Future<bool> Function()? hasNetwork,
  }) : _dbHelper = dbHelper ?? AppDatabase.instance {
    _runner = QueueRunner(
      store: this,
      sender: sender ?? DioReportSender(dio),
      hasNetwork: hasNetwork ?? _deviceHasNetwork,
    );
  }

  static ReportQueueRepository? _instance;

  static ReportQueueRepository get instance => _instance ??= ReportQueueRepository(
        dio: Dio(
          BaseOptions(
            baseUrl: ReportConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: const {'Accept': 'application/json'},
          ),
        ),
      );

  final AppDatabase _dbHelper;
  late final QueueRunner _runner;

  final StreamController<QueueRunResult> _results =
      StreamController<QueueRunResult>.broadcast();

  /// Ringkasan setiap putaran pengiriman yang selesai.
  Stream<QueueRunResult> get results => _results.stream;

  static Future<bool> _deviceHasNetwork() async {
    try {
      final List<ConnectivityResult> state = await Connectivity().checkConnectivity();
      return state.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true; // Biarkan percobaan HTTP yang menentukan.
    }
  }

  Future<bool> hasNetwork() => _deviceHasNetwork();

  // ------------------------------------------------------------------
  // Menulis antrean
  // ------------------------------------------------------------------

  /// Menyalin citra ke folder aplikasi lalu menyimpan laporan sebagai PENDING.
  Future<ReportQueueItem> enqueue(ReportQueueItem item) async {
    // image_picker sering mengembalikan path cache sementara. Citra disalin ke
    // folder dokumen agar laporan offline tetap ada setelah aplikasi ditutup.
    final ReportQueueItem persisted = await _persistImage(item);
    final Database db = await _dbHelper.database;
    await db.insert('report_queue', persisted.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return persisted;
  }

  Future<ReportQueueItem> _persistImage(ReportQueueItem item) async {
    final File source = File(item.imagePath);
    if (!await source.exists()) {
      throw const ReportQueueException(
        'Berkas citra tidak ditemukan; laporan belum masuk antrean.',
      );
    }
    final String extension = p.extension(source.path).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png'}.contains(extension)) {
      throw const ReportQueueException('Format citra harus JPG, JPEG, atau PNG.');
    }
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory imageDirectory =
        Directory(p.join(appDirectory.path, 'mobile_report_queue'));
    await imageDirectory.create(recursive: true);
    final File destination = File(p.join(imageDirectory.path, '${item.id}$extension'));
    if (!await destination.exists()) {
      await source.copy(destination.path);
    }
    return item.copyWith(imagePath: destination.path);
  }

  // ------------------------------------------------------------------
  // Membaca antrean
  // ------------------------------------------------------------------

  Future<ReportQueueItem?> getItemById(String id) async {
    final Database db = await _dbHelper.database;
    final rows = await db.query('report_queue', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ReportQueueItem.fromMap(rows.first);
  }

  Future<List<ReportQueueItem>> getAllQueueItems() async {
    final Database db = await _dbHelper.database;
    final rows = await db.query('report_queue', orderBy: 'created_at DESC');
    return rows.map(ReportQueueItem.fromMap).toList();
  }

  /// Mencegah laporan ganda untuk satu hasil identifikasi.
  Future<bool> hasReportFor(int historyId, ReportType type) async {
    final Database db = await _dbHelper.database;
    final rows = await db.query(
      'report_queue',
      columns: ['id'],
      where: 'history_id = ? AND report_type = ?',
      whereArgs: [historyId, type.value],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<ReportQueueItem>> pendingItems() async {
    final Database db = await _dbHelper.database;
    final rows = await db.query(
      'report_queue',
      where: 'upload_status = ?',
      whereArgs: [UploadStatus.pending.value],
      orderBy: 'created_at ASC, rowid ASC',
    );
    return rows.map(ReportQueueItem.fromMap).toList();
  }

  @override
  Future<int> countPending() async {
    final Database db = await _dbHelper.database;
    final int? count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM report_queue WHERE upload_status IN (?, ?)',
      [UploadStatus.pending.value, UploadStatus.sending.value],
    ));
    return count ?? 0;
  }

  // ------------------------------------------------------------------
  // Status
  // ------------------------------------------------------------------

  @override
  Future<void> updateStatus(
    String id, {
    required UploadStatus status,
    int? attemptCount,
    String? lastError,
  }) async {
    final Database db = await _dbHelper.database;
    await db.update(
      'report_queue',
      {
        'upload_status': status.value,
        if (attemptCount != null) 'attempt_count': attemptCount,
        'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> recoverInterrupted() async {
    final Database db = await _dbHelper.database;
    await db.update(
      'report_queue',
      {
        'upload_status': UploadStatus.pending.value,
        'last_error': 'Percobaan sebelumnya terhenti; dicoba kembali.',
      },
      where: 'upload_status = ?',
      whereArgs: [UploadStatus.sending.value],
    );
  }

  Future<void> retryFailedItem(String id) =>
      updateStatus(id, status: UploadStatus.pending, attemptCount: 0, lastError: null);

  Future<void> retryAllFailed() async {
    final Database db = await _dbHelper.database;
    await db.update(
      'report_queue',
      {'upload_status': UploadStatus.pending.value, 'attempt_count': 0, 'last_error': null},
      where: 'upload_status = ?',
      whereArgs: [UploadStatus.failed.value],
    );
  }

  // ------------------------------------------------------------------
  // Pengiriman
  // ------------------------------------------------------------------

  bool get isProcessing => _runner.isRunning;

  /// Mengirim antrean secara berurutan. Aman dipanggil berkali-kali.
  ///
  /// Mengembalikan null bila putaran lain sedang berjalan; hasil putaran
  /// itu tetap diumumkan lewat [results].
  Future<QueueRunResult?> processQueue() async {
    final QueueRunResult? result = await _runner.run();
    if (result != null) _results.add(result);
    return result;
  }
}

class ReportQueueException implements Exception {
  const ReportQueueException(this.message);
  final String message;

  @override
  String toString() => message;
}
