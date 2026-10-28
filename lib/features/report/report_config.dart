/// Konfigurasi pengiriman laporan dan koneksi server.
abstract final class ReportConfig {
  /// Ubah menjadi `false` saat aplikasi siap dihubungkan ke kalimantanbio.com
  static const bool isLocalDev = true;

  /// Gunakan '10.0.2.2:8001' untuk Android Emulator,
  /// atau ganti dengan IP Wi-Fi laptop (misal '192.168.1.10:8001') jika pakai HP fisik.
  static const String localHost = '192.168.1.14:8001';
  static const String prodHost = 'kalimantanbio.com';

  /// Nama host yang tampil pada teks popup.
  static const String serverHost = isLocalDev ? localHost : prodHost;

  /// Base URL utama portal
  static const String portalBaseUrl =
  isLocalDev ? 'http://$localHost' : 'https://$prodHost';

  /// Base URL untuk Dio pada ReportQueueRepository (/api/v1)
  static const String apiBaseUrl = '$portalBaseUrl/api/v1';

  /// URL WebView untuk Katalog Spesies & Peta Distribusi (Saran Dosen)
  static const String catalogWebViewUrl = '$portalBaseUrl/repository/';
  static const String mapDistributionWebViewUrl = '$portalBaseUrl/gis/map/species/';

  /// Radius penyamaran koordinat yang dijanjikan kepada pengguna (kilometer).
  static const int approximationRadiusKm = 10;
}