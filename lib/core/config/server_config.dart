/// Konfigurasi tunggal untuk seluruh host yang diakses aplikasi.
///
/// Seluruh endpoint (REST API, katalog WebView, peta WebView) diturunkan/// dari satu `baseUrl`, sehingga katalog dan API tidak mungkin menunjuk
/// ke host berbeda.
///
/// Production (default, tanpa --dart-define):
///   flutter build apk --release        -> https://kalimantanbio.com
///
/// Development via Wi-Fi (HP fisik):
///   flutter run --dart-define=IS_LOCAL_DEV=true --dart-define=LOCAL_HOST=192.168.1.14
///
/// Development via USB:
///   adb reverse tcp:8001 tcp:8001
///   flutter run --dart-define=IS_LOCAL_DEV=true --dart-define=LOCAL_HOST=127.0.0.1
class ServerConfig {
  /// true  -> memakai host development
  /// false -> memakai host production (default)
  static const bool isLocalDev =
  bool.fromEnvironment('IS_LOCAL_DEV', defaultValue: false);

  static const String localHost =
  String.fromEnvironment('LOCAL_HOST', defaultValue: '192.168.1.14');

  static const String prodHost = 'kalimantanbio.com';

  /// Override manual. Bila kosong, dipakai isLocalDev/prodHost.
  static const String _baseOverride =
  String.fromEnvironment('BIO_SERVER_BASE_URL', defaultValue: '');

  /// Host dasar aplikasi. Default: production (https://kalimantanbio.com).
  static const String baseUrl = _baseOverride != ''
      ? _baseOverride
      : (isLocalDev ? 'http://$localHost' : 'https://$prodHost');

  /// Alias agar kompatibel dengan ReportConfig.portalBaseUrl.
  static const String portalBaseUrl = baseUrl;

  static const String serverHost = baseUrl;
  static const String apiBaseUrl = '$baseUrl/api/v1/';

  /// Katalog website: filter Plantae (ID kingdom = 2 pada database lokal saat ini).
  static const String catalogWebViewUrl = '$baseUrl/repository/?kingdom=2';
  static const String mapDistributionWebViewUrl = '$baseUrl/gis/map/species/';

  /// Link web kanonik untuk satu spesies. Portal memakai id numerik.
  static String speciesWebUrl(int id) => '$baseUrl/repository/$id/';

  static const int approximationRadiusKm = 10;
}