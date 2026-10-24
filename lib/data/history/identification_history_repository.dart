import 'identification_record.dart';

/// Penyimpanan riwayat identifikasi di perangkat. Layar dan controller hanya
/// mengenal antarmuka ini, jadi implementasinya bisa diganti ke SQLite tanpa
/// mengubah kode lain.
abstract interface class IdentificationHistoryRepository {
  /// Semua riwayat, yang paling baru diambil lebih dulu.
  Future<List<IdentificationRecord>> loadAll();

  /// Menyimpan baris baru dan mengembalikannya lengkap dengan id.
  /// Selalu memberi id baru, id pada [record] diabaikan.
  Future<IdentificationRecord> add(IdentificationRecord record);

  /// Mengganti baris yang id-nya sama.
  Future<void> update(IdentificationRecord record);

  Future<void> delete(int id);

  Future<void> clear();
}
