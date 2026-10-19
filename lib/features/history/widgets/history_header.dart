import 'package:flutter/material.dart';

import '../../identification/identification_theme.dart';
import '../../identification/widgets/square_icon_button.dart';

/// Bagian gelap di atas layar riwayat: bilah atas, judul, dan statistik.
class HistoryHeader extends StatelessWidget {
  const HistoryHeader({
    super.key,
    required this.total,
    required this.savedCount,
    required this.speciesCount,
    required this.onBack,
    this.onClear,
  });

  final int total;
  final int savedCount;
  final int speciesCount;
  final VoidCallback onBack;

  /// Null menyembunyikan tombol hapus semua (saat riwayat kosong).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final VoidCallback? onClear = this.onClear;

    return Container(
      width: double.infinity,
      color: IdentColors.background,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SquareIconButton(
                icon: Icons.arrow_back,
                label: 'Kembali',
                onTap: onBack,
              ),
              Expanded(
                child: Center(
                  child: Text('RIWAYAT', style: IdentText.label()),
                ),
              ),
              if (onClear == null)
                const SizedBox(width: 40, height: 40)
              else
                SquareIconButton(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Hapus semua riwayat',
                  onTap: onClear,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Riwayat\nidentifikasi', style: IdentText.serif(size: 30)),
          const SizedBox(height: 10),
          Text(
            'Hasil yang berhasil dikenali tersimpan di perangkat ini.',
            style: IdentText.body(
              size: 13,
              color: IdentColors.bodyOnDark,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Stat(value: total, caption: 'HASIL'),
              const SizedBox(width: 32),
              _Stat(value: savedCount, caption: 'TERSIMPAN'),
              const SizedBox(width: 32),
              _Stat(value: speciesCount, caption: 'SPESIES'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.caption});

  final int value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: IdentText.body(
            size: 26,
            color: IdentColors.lime,
            weight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(caption, style: IdentText.label(size: 9, spacing: 1.2)),
      ],
    );
  }
}
