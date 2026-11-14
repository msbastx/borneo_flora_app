import '../../core/config/server_config.dart';

/// Konfigurasi portal dan REST API untuk development/production.
///
/// Seluruh definisi diteruskan ke `ServerConfig` sebagai satu sumber
/// kebenaran. Jangan menambahkan konstanta host baru di file ini.
abstract final class ReportConfig {
  static const bool isLocalDev = ServerConfig.isLocalDev;
  static const String localHost = ServerConfig.localHost;
  static const String prodHost = ServerConfig.prodHost;

  static const String portalBaseUrl = ServerConfig.portalBaseUrl;
  static const String serverHost = ServerConfig.serverHost;
  static const String apiBaseUrl = ServerConfig.apiBaseUrl;

  static const String catalogWebViewUrl = ServerConfig.catalogWebViewUrl;
  static const String mapDistributionWebViewUrl =
      ServerConfig.mapDistributionWebViewUrl;

  static const int approximationRadiusKm = ServerConfig.approximationRadiusKm;
}