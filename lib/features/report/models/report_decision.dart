/// Pilihan pengguna pada popup pengiriman laporan.
class ReportDecision {
  const ReportDecision({
    required this.send,
    this.allowTraining = false,
    this.approximateLocation = false,
  });

  /// Pilihan "Jangan kirim", juga dipakai saat popup ditutup tanpa memilih.
  const ReportDecision.skip()
      : send = false,
        allowTraining = false,
        approximateLocation = false;

  final bool send;

  /// Izin memakai citra sebagai data pelatihan. Hanya untuk citra tidak dikenali.
  final bool allowTraining;

  /// Koordinat dibulatkan sebelum dikirim. Hanya untuk temuan endemik.
  final bool approximateLocation;
}
