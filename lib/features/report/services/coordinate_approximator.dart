/// Membulatkan koordinat ke grid 0,1 derajat agar lokasi presisi tidak terkirim.
///
/// Pergeseran maksimum 0,05 derajat per sumbu. Di sekitar khatulistiwa itu
/// sekitar 5,6 km per sumbu atau 7,9 km secara diagonal, sehingga selalu
/// berada di dalam radius 10 km yang dijanjikan kepada pengguna.
abstract final class CoordinateApproximator {
  static ({double latitude, double longitude}) approximate(
    double latitude,
    double longitude,
  ) {
    double snap(double value) => (value * 10).round() / 10;
    return (latitude: snap(latitude), longitude: snap(longitude));
  }
}
