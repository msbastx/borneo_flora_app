/// Identitas singkat pelapor yang diisi sekali setelah panduan awal.
class ReporterProfile {
  const ReporterProfile({
    this.name = '',
    this.email = '',
    this.datasetConsent = true,
  });

  final String name;
  final String email;

  /// Izin mengirim otomatis foto flora non-endemik untuk dataset model.
  final bool datasetConsent;

  static const int maxNameLength = 120;

  bool get isEmpty => name.trim().isEmpty && email.trim().isEmpty;

  ReporterProfile normalized() => ReporterProfile(
        name: name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' '),
        email: email.trim().toLowerCase(),
        datasetConsent: datasetConsent,
      );

  /// Pesan galat untuk nama, atau null bila valid. Nama wajib diisi.
  static String? validateName(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Nama wajib diisi.';
    if (text.length > maxNameLength) return 'Nama maksimal $maxNameLength karakter.';
    return null;
  }

  /// Email boleh kosong. Bila diisi, formatnya harus valid.
  static String? validateEmail(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final RegExp pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    return pattern.hasMatch(text) ? null : 'Format email tidak valid.';
  }
}
