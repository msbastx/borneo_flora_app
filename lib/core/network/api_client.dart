import 'package:dio/dio.dart';
import '../config/server_config.dart';

/// Satu konfigurasi HTTP untuk seluruh API Django.
///
/// Base URL diturunkan dari `ServerConfig`, sehingga API REST, katalog WebView,
/// dan peta WebView dijamin menunjuk ke host yang sama.
///
/// Production (default, tanpa --dart-define):
///   flutter build apk --release          -> https://kalimantanbio.com
///
/// Development via Wi-Fi (HP fisik):
///   flutter run --dart-define=IS_LOCAL_DEV=true --dart-define=LOCAL_HOST=192.168.1.14
///
/// Development via USB:
///   adb reverse tcp:8001 tcp:8001
///   flutter run --dart-define=IS_LOCAL_DEV=true --dart-define=LOCAL_HOST=127.0.0.1
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiClient._withTrailingSlash(ServerConfig.apiBaseUrl),
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