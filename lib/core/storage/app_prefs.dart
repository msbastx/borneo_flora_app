import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/reporter_profile.dart';

/// Satu pintu untuk semua data lokal ringan aplikasi.
/// Setiap data baru cukup menambah satu kunci dan satu pasang method.
class AppPrefs {
  AppPrefs._();

  // Daftar kunci dikumpulkan di sini agar tidak ada yang bentrok.
  static const String _kGuideSeen = 'capture_guide_seen';
  static const String _kProfileAsked = 'reporter_profile_asked';
  static const String _kReporterName = 'reporter_name';
  static const String _kReporterEmail = 'reporter_email';
  static const String _kDatasetConsent = 'reporter_dataset_consent';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- Panduan pengambilan citra ----

  static Future<bool> hasSeenGuide() async =>
      (await _prefs).getBool(_kGuideSeen) ?? false;

  static Future<void> markGuideSeen() async =>
      (await _prefs).setBool(_kGuideSeen, true);

  // ---- Profil pelapor ----

  /// True setelah formulir profil pernah ditampilkan (diisi atau dilewati).
  static Future<bool> hasAskedProfile() async =>
      (await _prefs).getBool(_kProfileAsked) ?? false;

  static Future<void> markProfileAsked() async =>
      (await _prefs).setBool(_kProfileAsked, true);

  static Future<ReporterProfile> reporterProfile() async {
    final SharedPreferences prefs = await _prefs;
    return ReporterProfile(
      name: prefs.getString(_kReporterName) ?? '',
      email: prefs.getString(_kReporterEmail) ?? '',
      datasetConsent: prefs.getBool(_kDatasetConsent) ?? false,
    );
  }

  static Future<void> saveReporterProfile(ReporterProfile profile) async {
    final SharedPreferences prefs = await _prefs;
    final ReporterProfile p = profile.normalized();
    await prefs.setString(_kReporterName, p.name);
    await prefs.setString(_kReporterEmail, p.email);
    await prefs.setBool(_kDatasetConsent, p.datasetConsent);
    await prefs.setBool(_kProfileAsked, true);
  }

  // ---- Reset (untuk pengujian) ----

  static Future<void> resetAll() async => (await _prefs).clear();
}
