import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/format.dart';
import '../../../data/history/identification_record.dart';
import '../../identification/identification_theme.dart';
import '../../identification/models/identified_flora.dart';
import '../../identification/widgets/progress_bar.dart';

/// Satu baris riwayat: gambar, nama, keyakinan, dan penanda simpan.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.record,
    required this.top,
    required this.onTap,
    required this.onToggleSaved,
  });

  final IdentificationRecord record;

  /// Kandidat teratas yang sudah dipasangkan dengan data katalog.
  final IdentifiedFlora top;

  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IdentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: IdentColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(path: record.imagePath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatClockWithZone(record.capturedAt),
                      style: IdentText.label(
                        color: IdentColors.mutedOnLight,
                        size: 9.5,
                        spacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      top.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: IdentText.serif(
                        size: 17,
                        color: IdentColors.green,
                        height: 1.2,
                      ),
                    ),
                    if (top.showsScientificName) ...[
                      const SizedBox(height: 2),
                      Text(
                        top.scientificName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: IdentText.body(
                          size: 12,
                          color: IdentColors.mutedOnLight,
                          style: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ProgressBar(
                            value: record.confidence,
                            height: 4,
                            fillColor: IdentColors.green,
                            trackColor: IdentColors.barTrack,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatPercent(record.confidence),
                          style: IdentText.label(
                            color: IdentColors.green,
                            size: 11,
                            weight: FontWeight.w700,
                            spacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: record.isSaved ? 'Hapus penanda simpan' : 'Simpan hasil',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleSaved,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      record.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 22,
                      color: record.isSaved
                          ? IdentColors.green
                          : IdentColors.mutedOnLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    // Berkas bisa hilang bila cache dibersihkan sistem, tampilkan placeholder.
    const Widget placeholder = ColoredBox(
      color: IdentColors.placeholderTile,
      child: Center(
        child: Icon(
          Icons.local_florist_outlined,
          size: 22,
          color: Color(0x591F5A33),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 72,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: 200,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}
