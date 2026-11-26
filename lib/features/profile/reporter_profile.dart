/// Identitas singkat pelapor yang diisi sekali setelah panduan awal.
class ReporterProfile {
  const ReporterProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.datasetConsent = true,
  });

  final String name;
  final String email;

  /// Nomor telepon atau WhatsApp. Opsional.
  final String phone;

  /// Izin mengirim otomatis foto flora non-endemik untuk dataset model.
  final bool datasetConsent;

  static const int maxNameLength = 120;

  bool get isEmpty =>
      name.trim().isEmpty && email.trim().isEmpty && phone.trim().isEmpty;

  ReporterProfile normalized() => ReporterProfile(
        name: name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' '),
        email: email.trim().toLowerCase(),
        phone: normalizePhone(phone),
        datasetConsent: datasetConsent,
      );

  /// Pesan galat untuk nama, atau null bila valid. Nama wajib diisi.
  static String? validateName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Nama wajib diisi.';
    if (text.length > maxNameLength) return 'Nama maksimal $maxNameLength karakter.';
    return null;
  }

  /// Membuang spasi, tanda "-", dan kurung. Contoh: "+62 812-3456" -> "+628123456".
  static String normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Nomor telepon boleh kosong. Bila diisi: 8 sampai 15 digit, boleh diawali "+".
  /// Aturan ini sama dengan validasi di server (`mobile_review/views.py`).
  static String? validatePhone(String? value) {
    final String text = normalizePhone(value ?? '');
    if (text.isEmpty) return null;
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(text)
        ? null
        : 'Nomor telepon harus 8 sampai 15 digit angka.';
  }

  /// Email boleh kosong. Bila diisi, formatnya harus valid.
  static String? validateEmail(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final RegExp pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    return pattern.hasMatch(text) ? null : 'Format email tidak valid.';
  }
}
