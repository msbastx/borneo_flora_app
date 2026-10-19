import '../models/report_draft.dart';

/// Antrean laporan lokal. Implementasi SQLite menyusul setelah skema disetujui.
abstract interface class ReportQueueRepository {
  /// Menyimpan laporan ke antrean dan mengembalikan id barisnya.
  Future<int> enqueue(ReportDraft draft);
}
