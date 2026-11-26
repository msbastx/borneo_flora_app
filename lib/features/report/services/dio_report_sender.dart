import 'dart:io';

import 'package:dio/dio.dart';

import '../models/report_queue_item.dart';
import 'queue_runner.dart';

/// Mengirim satu laporan ke REST API memakai Dio.
///
/// Laporan dikirim ke endpoint baru (`reports/...`) yang ikut menyimpan nama
/// dan email pelapor. Bila server belum memiliki endpoint itu (halaman 404
/// bukan JSON), laporan dikirim ulang ke endpoint lama tanpa data pelapor,
/// sehingga aplikasi tetap bekerja selama server belum diperbarui.
class DioReportSender implements ReportSender {
  DioReportSender(this._dio);

  final Dio _dio;

  @override
  Future<SendOutcome> send(ReportQueueItem item) async {
    final File file = File(item.imagePath);
    if (!await file.exists()) {
      return const SendOutcome(
        SendOutcomeKind.permanent,
        message: 'Berkas citra tidak ditemukan di perangkat.',
      );
    }

    try {
      await _post(item, item.reportType.endpoint, includeReporter: true);
      return const SendOutcome.sent();
    } on DioException catch (error) {
      if (_isMissingRoute(error)) {
        try {
          await _post(item, item.reportType.legacyEndpoint, includeReporter: false);
          return const SendOutcome.sent();
        } on DioException catch (legacyError) {
          return _toOutcome(legacyError);
        }
      }
      return _toOutcome(error);
    }
  }

  Future<void> _post(
    ReportQueueItem item,
    String endpoint, {
    required bool includeReporter,
  }) async {
    final FormData form = FormData.fromMap({
      ...item.formFields(includeReporter: includeReporter),
      'image': await MultipartFile.fromFile(item.imagePath),
    });
    // Base URL berakhir dengan /api/v1/. Endpoint tidak diawali slash agar
    // Dio tidak membuang path /api/v1/.
    final Response<Object?> response = await _dio.post<Object?>(
      endpoint,
      data: form,
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final int code = response.statusCode ?? 0;
    if (code != 200 && code != 201) {
      throw DioException.badResponse(
        statusCode: code,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
  }

  /// Endpoint belum ada di server: Django mengembalikan halaman HTML 404.
  /// Balasan 404 berbentuk JSON berarti endpoint ada tetapi isi laporan
  /// ditolak (misalnya spesies tidak ditemukan), jadi tidak dialihkan.
  static bool _isMissingRoute(DioException error) {
    if (error.response?.statusCode != 404) return false;
    final Object? data = error.response?.data;
    return !(data is Map && data.containsKey('error'));
  }

  static SendOutcome _toOutcome(DioException error) {
    final bool connection = error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        (error.type == DioExceptionType.unknown && error.error is SocketException);
    final bool timedOut = error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
    final Object? data = error.response?.data;
    final String? detail = data is Map ? (data['error'] ?? data['detail'])?.toString() : null;
    return classifyHttpResult(
      statusCode: error.response?.statusCode,
      connectionError: connection,
      timedOut: timedOut,
      detail: detail,
    );
  }
}
