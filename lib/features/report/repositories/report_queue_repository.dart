import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/storage/app_database.dart';
import '../models/report_queue_item.dart';

class ReportQueueRepository {
  final AppDatabase _dbHelper;
  final Dio _dio;

  ReportQueueRepository({
    AppDatabase? dbHelper,
    required Dio dio,
  })  : _dbHelper = dbHelper ?? AppDatabase.instance,
        _dio = dio;

  /// 1. Simpan laporan baru ke antrean lokal (Status awal: PENDING)
  Future<void> enqueue(ReportQueueItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'report_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 2. Ambil semua item yang siap dikirim (PENDING) diurutkan dari yang terlama
  Future<List<ReportQueueItem>> getPendingItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'report_queue',
      where: 'upload_status = ?',
      whereArgs: [UploadStatus.pending.value],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ReportQueueItem.fromMap(m)).toList();
  }

  /// 3. Ambil semua daftar antrean (untuk ditampilkan di UI Status Antrean - Layar No. 11)
  Future<List<ReportQueueItem>> getAllQueueItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query('report_queue', orderBy: 'created_at DESC');
    return maps.map((m) => ReportQueueItem.fromMap(m)).toList();
  }

  /// 4. Perbarui status item di SQLite
  Future<void> updateStatus(
      String id, {
        required UploadStatus status,
        int? attemptCount,
        String? lastError,
      }) async {
    final db = await _dbHelper.database;
    final values = <String, dynamic>{
      'upload_status': status.value,
      if (attemptCount != null) 'attempt_count': attemptCount,
      'last_error': lastError,
    };
    await db.update(
      'report_queue',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 5. Reset item FAILED menjadi PENDING saat pengguna menekan tombol "Kirim Ulang" (MB-17)
  Future<void> retryFailedItem(String id) async {
    await updateStatus(
      id,
      status: UploadStatus.pending,
      attemptCount: 0,
      lastError: null,
    );
  }

  /// 6. Proses antrean satu per satu dari yang terlama (Sesuai Flowchart Gambar 3.5a)
  Future<void> processQueue() async {
    final pendingItems = await getPendingItems();

    for (final item in pendingItems) {
      await _sendSingleItemWithRetry(item);
    }
  }

  Future<void> _sendSingleItemWithRetry(ReportQueueItem item) async {
    await updateStatus(item.id, status: UploadStatus.sending);

    // Sesuai Tabel 3.28 No. 11: Jumlah percobaan ulang otomatis = 2 kali (Total maksimal 3 eksekusi)
    const int maxAttemptsPerRound = 3;
    int currentAttempt = item.attemptCount;

    while (currentAttempt < maxAttemptsPerRound) {
      try {
        await _uploadToRestApi(item);

        // Berhasil diterima server (200 / 201) -> Tandai SENT
        await updateStatus(
          item.id,
          status: UploadStatus.sent,
          attemptCount: currentAttempt + 1,
          lastError: null,
        );
        return;
      } on DioException catch (e) {
        currentAttempt++;
        final errorMessage = _mapDioErrorToMessage(e);

        // Jika galat berasal dari penolakan berkas (400 / 413), jangan di-retry otomatis
        final statusCode = e.response?.statusCode;
        if (statusCode == 400 || statusCode == 413) {
          await updateStatus(
            item.id,
            status: UploadStatus.failed,
            attemptCount: currentAttempt,
            lastError: errorMessage,
          );
          return;
        }

        if (currentAttempt >= maxAttemptsPerRound) {
          // 3 pengulangan gagal -> Tandai FAILED (Sesuai Gambar 3.5a)
          await updateStatus(
            item.id,
            status: UploadStatus.failed,
            attemptCount: currentAttempt,
            lastError: errorMessage,
          );
        } else {
          // Masih ada jatah retry, simpan status kembali ke PENDING sementara
          await updateStatus(
            item.id,
            status: UploadStatus.pending,
            attemptCount: currentAttempt,
            lastError: errorMessage,
          );
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        currentAttempt++;
        await updateStatus(
          item.id,
          status: currentAttempt >= maxAttemptsPerRound
              ? UploadStatus.failed
              : UploadStatus.pending,
          attemptCount: currentAttempt,
          lastError: e.toString(),
        );
      }
    }
  }

  /// Pengiriman HTTP Multipart ke Endpoint Django REST Framework (Tabel 3.24)
  Future<void> _uploadToRestApi(ReportQueueItem item) async {
    final file = File(item.imagePath);
    if (!await file.exists()) {
      throw Exception('Berkas citra tidak ditemukan di perangkat.');
    }

    final formData = FormData.fromMap({
      'client_id': item.id, // UUID unik pencegah duplikasi (MBN-11)
      'image': await MultipartFile.fromFile(item.imagePath),
      if (item.aiKey != null) 'ai_key': item.aiKey,
      if (item.latitude != null) 'latitude': item.latitude,
      if (item.longitude != null) 'longitude': item.longitude,
      'created_at': item.createdAt.toIso8601String(),
    });

    final endpoint = item.reportType == ReportType.unknownImage
        ? '/unknown-images'
        : '/findings';

    await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 15), // Sesuai Tabel 3.28 No. 10 (15 detik)
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  /// Pemenuhan MB-16: Membedakan kegagalan jaringan, penolakan berkas, dan kegagalan layanan
  String _mapDioErrorToMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Kegagalan jaringan: Koneksi terputus atau melewati batas waktu (15 detik).';
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 400 || statusCode == 413) {
      return 'Penolakan berkas: Format citra harus JPG/PNG dan ukuran maksimal 5 MB.';
    } else if (statusCode == 401) {
      return 'Kegagalan layanan: Kredensial aplikasi tidak sah (401).';
    } else if (statusCode == 429) {
      return 'Kegagalan layanan: Batas pengiriman terlampaui, coba lagi nanti (429).';
    } else {
      return 'Kegagalan layanan server (${statusCode ?? "Unknown"}).';
    }
  }
}