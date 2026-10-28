import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../models/report_queue_item.dart';

class ReportQueueRepository {
  final AppDatabase _dbHelper;
  final Dio _dio;
  static bool _isProcessingQueue = false;
  static bool _processQueueAgain = false;

  ReportQueueRepository({AppDatabase? dbHelper, required Dio dio})
      : _dbHelper = dbHelper ?? AppDatabase.instance,
        _dio = dio;

  Future<void> enqueue(ReportQueueItem item) async {
    // image_picker commonly returns a cache/temp path. Copy it into the app's
    // documents directory so an offline report can survive process restarts.
    final persistedItem = await _persistImage(item);
    final db = await _dbHelper.database;
    await db.insert('report_queue', persistedItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReportQueueItem> _persistImage(ReportQueueItem item) async {
    final source = File(item.imagePath);
    if (!await source.exists()) {
      throw const _PermanentQueueException(
        'Berkas citra tidak ditemukan; laporan belum masuk antrean.',
      );
    }

    final String extension = p.extension(source.path).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png'}.contains(extension)) {
      throw const _PermanentQueueException(
        'Format citra antrean harus JPG, JPEG, atau PNG.',
      );
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(p.join(appDirectory.path, 'mobile_report_queue'));
    await imageDirectory.create(recursive: true);
    final destination = File(p.join(imageDirectory.path, '${item.id}$extension'));
    if (!await destination.exists()) {
      await source.copy(destination.path);
    }

    return item.copyWith(imagePath: destination.path);
  }

  Future<ReportQueueItem?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('report_queue', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ReportQueueItem.fromMap(rows.first);
  }

  Future<List<ReportQueueItem>> getPendingItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'report_queue',
      where: 'upload_status = ?',
      whereArgs: [UploadStatus.pending.value],
      orderBy: 'created_at ASC',
    );
    return maps.map(ReportQueueItem.fromMap).toList();
  }

  Future<List<ReportQueueItem>> getAllQueueItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query('report_queue', orderBy: 'created_at DESC');
    return maps.map(ReportQueueItem.fromMap).toList();
  }

  Future<void> updateStatus(
    String id, {
    required UploadStatus status,
    int? attemptCount,
    String? lastError,
  }) async {
    final db = await _dbHelper.database;
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

  Future<void> retryFailedItem(String id) => updateStatus(
        id, status: UploadStatus.pending, attemptCount: 0, lastError: null);

  /// Proses berurutan. Jika jaringan gagal, item kembali PENDING agar bisa
  /// dicoba saat connectivity berubah atau aplikasi dibuka lagi.
  Future<void> processQueue() async {
    // One process-wide lock avoids simultaneous sends from AppShell and a
    // screen-created repository instance. A call during processing requests
    // one more pass so an item enqueued mid-round is not stranded as PENDING.
    if (_isProcessingQueue) {
      _processQueueAgain = true;
      return;
    }
    _isProcessingQueue = true;
    try {
      final db = await _dbHelper.database;
      // Recover records left in SENDING if Android killed the app mid-upload.
      await db.update(
        'report_queue',
        {
          'upload_status': UploadStatus.pending.value,
          'last_error': 'Percobaan sebelumnya terhenti; akan dicoba kembali.',
        },
        where: 'upload_status = ?',
        whereArgs: [UploadStatus.sending.value],
      );

      do {
        _processQueueAgain = false;
        final pendingItems = await getPendingItems();
        for (final item in pendingItems) {
          await _sendSingleItemWithRetry(item);
        }
      } while (_processQueueAgain);
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _sendSingleItemWithRetry(ReportQueueItem item) async {
    await updateStatus(item.id, status: UploadStatus.sending);
    const int maxAttemptsPerRound = 3;
    int attemptsThisRound = 0;
    int totalAttempts = item.attemptCount;
    String? lastError = item.lastError;

    while (attemptsThisRound < maxAttemptsPerRound) {
      attemptsThisRound++;
      totalAttempts++;
      try {
        await _uploadToRestApi(item);
        await updateStatus(item.id, status: UploadStatus.sent,
            attemptCount: totalAttempts, lastError: null);
        return;
      } on DioException catch (error) {
        lastError = _mapDioErrorToMessage(error);
        final code = error.response?.statusCode;
        // Kesalahan payload bersifat permanen sampai pengguna memperbaiki data.
        if (code == 400 || code == 401 || code == 403 || code == 404 ||
            code == 405 || code == 409 || code == 413 || code == 415 ||
            code == 422) {
          await updateStatus(item.id, status: UploadStatus.failed,
              attemptCount: totalAttempts, lastError: lastError);
          return;
        }
        if (attemptsThisRound < maxAttemptsPerRound) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      } on _PermanentQueueException catch (error) {
        await updateStatus(item.id, status: UploadStatus.failed,
            attemptCount: totalAttempts, lastError: error.message);
        return;
      } catch (error) {
        lastError = error.toString();
        if (attemptsThisRound < maxAttemptsPerRound) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }

    // Jangan set FAILED untuk gangguan jaringan sementara: retry pada event berikutnya.
    await updateStatus(item.id, status: UploadStatus.pending,
        attemptCount: totalAttempts, lastError: lastError ?? 'Belum dapat terhubung ke server.');
  }

  Future<void> _uploadToRestApi(ReportQueueItem item) async {
    final file = File(item.imagePath);
    if (!await file.exists()) {
      throw const _PermanentQueueException('Berkas citra tidak ditemukan di perangkat.');
    }

    final formData = FormData.fromMap({
      'client_id': item.id,
      'image': await MultipartFile.fromFile(item.imagePath),
      if (item.aiKey != null) 'ai_key': item.aiKey,
      if (item.latitude != null) 'latitude': item.latitude,
      if (item.longitude != null) 'longitude': item.longitude,
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'allow_training': item.allowTraining,
      if (item.confidence != null) 'confidence': item.confidence,
      if (item.modelVersion != null) 'model_version': item.modelVersion,
      'coordinate_approximate': item.coordinateApproximate,
    });

    // Base URL berakhir dengan /api/v1/. Jangan awali endpoint dengan slash,
    // karena Dio akan membuang path /api/v1/.
    final String endpoint = item.reportType == ReportType.unknownImage
        ? 'unknown-images/'
        : 'findings/';

    await _dio.post<Object?>(
      endpoint,
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  String _mapDioErrorToMessage(DioException error) {
    final code = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Jaringan tidak tersedia atau server belum dapat dijangkau.';
    }
    if (code == 400 || code == 413 || code == 422) {
      final detail = error.response?.data;
      return 'Server menolak data laporan ($code): $detail';
    }
    if (code == 401 || code == 403) return 'Permintaan tidak diizinkan ($code).';
    if (code == 429) return 'Terlalu banyak permintaan. Coba lagi nanti.';
    return 'Kegagalan layanan server (${code ?? "unknown"}).';
  }
}

class _PermanentQueueException implements Exception {
  const _PermanentQueueException(this.message);
  final String message;
}
