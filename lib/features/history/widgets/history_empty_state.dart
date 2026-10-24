import 'package:flutter/material.dart';

import '../../identification/identification_theme.dart';
import '../history_controller.dart';

/// Tampilan saat daftar kosong. Teksnya mengikuti filter yang aktif.
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key, required this.filter});

  final HistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final bool saved = filter == HistoryFilter.saved;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            saved ? Icons.bookmark_border : Icons.history,
            size: 40,
            color: IdentColors.green.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            saved ? 'Belum ada yang disimpan' : 'Belum ada riwayat',
            textAlign: TextAlign.center,
            style: IdentText.serif(size: 22, color: IdentColors.green),
          ),
          const SizedBox(height: 8),
          Text(
            saved
                ? 'Ketuk ikon penanda pada sebuah hasil untuk menyimpannya.'
                : 'Hasil identifikasi yang berhasil dikenali akan muncul di sini.',
            textAlign: TextAlign.center,
            style: IdentText.body(color: IdentColors.mutedOnLight, height: 1.5),
          ),
        ],
      ),
    );
  }
}
