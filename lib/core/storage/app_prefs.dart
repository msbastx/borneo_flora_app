import 'package:shared_preferences/shared_preferences.dart';

/// Satu pintu untuk semua data lokal ringan aplikasi.
/// Setiap data baru cukup menambah satu kunci dan satu pasang method.
class AppPrefs {
  AppPrefs._();

  // Daftar kunci dikumpulkan di sini agar tidak ada yang bentrok.
  static const String _kGuideSeen = 'capture_guide_seen';
  // Contoh untuk tahap berikutnya:
  // static const String _kUserName = 'user_name';
  // static const String _kUserInstitution = 'user_institution';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- Panduan pengambilan citra ----

  static Future<bool> hasSeenGuide() async =>
      (await _prefs).getBool(_kGuideSeen) ?? false;

  static Future<void> markGuideSeen() async =>
      (await _prefs).setBool(_kGuideSeen, true);

  // ---- Reset (untuk pengujian) ----

  static Future<void> resetAll() async => (await _prefs).clear();
}
