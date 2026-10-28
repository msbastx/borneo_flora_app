/// Konfigurasi portal dan REST API untuk development/production.
///
/// Local development: gunakan adb reverse untuk perangkat USB:
///   adb reverse tcp:8001 tcp:8001
///   flutter run --dart-define=BIO_SERVER_BASE_URL=http://127.0.0.1:8001
/// Android Emulator: --dart-define=BIO_SERVER_BASE_URL=http://10.0.2.2:8001
/// HP melalui Wi-Fi: gunakan IP LAN laptop sebagai BIO_SERVER_BASE_URL.
abstract final class ReportConfig {
  static const bool isLocalDev = true;
  static const String localHost = '127.0.0.1:8001';
  static const String prodHost = 'kalimantanbio.com';

  /// Override tidak boleh diakhiri slash. Contoh: http://127.0.0.1:8001
  static const String _baseOverride = String.fromEnvironment(
    'BIO_SERVER_BASE_URL',
    defaultValue: '',
  );

  static const String portalBaseUrl = _baseOverride != ''
      ? _baseOverride
      : (isLocalDev ? 'http://$localHost' : 'https://$prodHost');

  static const String serverHost = portalBaseUrl;
  static const String apiBaseUrl = '$portalBaseUrl/api/v1/';

  /// Katalog website: filter Plantae (ID kingdom = 2 pada database lokal saat ini).
  static const String catalogWebViewUrl = '$portalBaseUrl/repository/?kingdom=2';
  static const String mapDistributionWebViewUrl = '$portalBaseUrl/gis/map/species/';

  static const int approximationRadiusKm = 10;
}
