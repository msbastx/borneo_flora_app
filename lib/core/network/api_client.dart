import 'package:dio/dio.dart';

/// Satu konfigurasi HTTP untuk seluruh API Django.
///
/// Default ditujukan untuk Android Emulator yang mengakses host Docker.
/// Untuk Flutter Windows, jalankan dengan:
/// --dart-define=API_BASE_URL=http://127.0.0.1:8001/api/v1/
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiClient._withTrailingSlash(
                  baseUrl ??
                      const String.fromEnvironment(
                        'API_BASE_URL',
                        defaultValue: 'http://10.0.2.2:8001/api/v1/',
                      ),
                ),
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
                sendTimeout: const Duration(seconds: 8),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio dio;

  static String _withTrailingSlash(String value) =>
      value.endsWith('/') ? value : '$value/';
}
