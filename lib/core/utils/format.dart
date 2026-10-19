/// Format angka dan teks gaya Indonesia (koma sebagai pemisah desimal).
String formatDecimal(double value, {int digits = 1}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// Probabilitas 0.0 sampai 1.0 menjadi teks persen, contoh `18,2%`.
String formatPercent(double probability, {int digits = 1}) =>
    '${formatDecimal(probability * 100, digits: digits)}%';

/// Ukuran berkas, contoh `2,1 MB`.
String formatFileSize(int bytes) {
  const int kb = 1024;
  const int mb = kb * 1024;
  if (bytes >= mb) return '${formatDecimal(bytes / mb)} MB';
  if (bytes >= kb) return '${formatDecimal(bytes / kb, digits: 0)} KB';
  return '$bytes B';
}

/// Ekstensi berkas huruf besar, contoh `JPG`.
String fileExtensionLabel(String path) {
  final int dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return 'FILE';
  return path.substring(dot + 1).toUpperCase();
}

/// Koordinat dengan 4 desimal, contoh `-1.1023, 116.8412`.
String formatCoordinates(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

/// Jam dan zona waktu Indonesia, contoh `09.41 WITA`.
String formatClockWithZone(DateTime time) {
  final DateTime local = time.toLocal();
  final String hh = local.hour.toString().padLeft(2, '0');
  final String mm = local.minute.toString().padLeft(2, '0');
  return '$hh.$mm ${_zoneLabel(local.timeZoneOffset)}';
}

String _zoneLabel(Duration offset) {
  final int hours = offset.inHours;
  return switch (hours) {
    7 => 'WIB',
    8 => 'WITA',
    9 => 'WIT',
    _ => 'UTC${hours >= 0 ? '+' : ''}$hours',
  };
}
