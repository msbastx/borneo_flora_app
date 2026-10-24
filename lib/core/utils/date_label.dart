const List<String> _monthLabels = [
  'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
  'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
];

/// Label hari untuk pengelompokan daftar: `HARI INI`, `KEMARIN`, atau
/// tanggal seperti `18 OKT 2026`. [now] bisa diisi saat pengujian.
String formatDayLabel(DateTime time, {DateTime? now}) {
  final DateTime local = time.toLocal();
  final DateTime today = (now ?? DateTime.now()).toLocal();
  final DateTime day = DateTime(local.year, local.month, local.day);
  final DateTime base = DateTime(today.year, today.month, today.day);
  final int diff = base.difference(day).inDays;

  if (diff == 0) return 'HARI INI';
  if (diff == 1) return 'KEMARIN';
  return '${local.day} ${_monthLabels[local.month - 1]} ${local.year}';
}
