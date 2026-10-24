import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../models/report_decision.dart';
import '../report_config.dart';
import 'report_sheet_parts.dart';

/// Popup untuk citra yang tidak dikenali model (keyakinan di bawah ambang).
/// Tampilkan dengan `showReportSheet(context, UnknownSpeciesSheet(...))`.
class UnknownSpeciesSheet extends StatefulWidget {
  const UnknownSpeciesSheet({
    super.key,
    required this.topConfidence,
    required this.threshold,
    required this.catalogCount,
    required this.capturedAt,
    this.imagePath,
    this.imageSizeBytes,
    this.latitude,
    this.longitude,
    this.initialAllowTraining = true,
  });

  /// Keyakinan tertinggi dari model, 0.0 sampai 1.0.
  final double topConfidence;

  /// Ambang keyakinan, 0.0 sampai 1.0.
  final double threshold;

  /// Jumlah spesies pada katalog.
  final int catalogCount;

  final DateTime capturedAt;
  final String? imagePath;
  final int? imageSizeBytes;
  final double? latitude;
  final double? longitude;

  /// Nilai awal saklar izin data pelatihan. Desain Figma menyalakannya.
  final bool initialAllowTraining;

  @override
  State<UnknownSpeciesSheet> createState() => _UnknownSpeciesSheetState();
}

class _UnknownSpeciesSheetState extends State<UnknownSpeciesSheet> {
  static const ReportSheetPalette _palette = ReportSheetPalette.dark;

  late bool _allowTraining = widget.initialAllowTraining;

  String get _imageTitle {
    final String? path = widget.imagePath;
    final int? size = widget.imageSizeBytes;
    final List<String> parts = [
      if (path != null) fileExtensionLabel(path),
      if (size != null) formatFileSize(size),
    ];
    return parts.isEmpty ? 'Citra Anda' : 'Citra Anda · ${parts.join(' ')}';
  }

  String get _imageDetail {
    final double? lat = widget.latitude;
    final double? lng = widget.longitude;
    final String time = formatClockWithZone(widget.capturedAt);
    if (lat == null || lng == null) return time;
    return '${formatCoordinates(lat, lng)} · $time';
  }

  void _skip() => Navigator.pop(context, const ReportDecision.skip());

  void _send() => Navigator.pop(
        context,
        ReportDecision(send: true, allowTraining: _allowTraining),
      );

  @override
  Widget build(BuildContext context) {
    final int thresholdPercent = (widget.threshold * 100).round();

    return SheetFrame(
      palette: _palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusChip(),
          const SizedBox(height: 16),
          Text(
            'Model belum bisa memastikan spesies ini',
            style: ReportSheetText.serif(_palette.title),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: ReportSheetText.sans(_palette.body),
              children: [
                const TextSpan(text: 'Keyakinan tertinggi hanya '),
                TextSpan(
                  text: formatPercent(widget.topConfidence),
                  style: ReportSheetText.sans(AppColors.neonLime, weight: FontWeight.w700),
                ),
                TextSpan(
                  text: ', di bawah ambang $thresholdPercent%. '
                      'Citra ini mungkin bukan flora Kalimantan, '
                      'atau belum ada dalam ${widget.catalogCount} rekaman kami.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _CapturedImageCard(
            palette: _palette,
            imagePath: widget.imagePath,
            title: _imageTitle,
            detail: _imageDetail,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SheetSwitch(
                palette: _palette,
                value: _allowTraining,
                onChanged: (v) => setState(() => _allowTraining = v),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Izinkan citra ini disimpan sebagai data pelatihan '
                  'agar model dapat mengenali spesies baru.',
                  style: ReportSheetText.sans(_palette.body, size: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SheetActionButtons(palette: _palette, onSkip: _skip, onSend: _send),
          const SizedBox(height: 14),
          SheetFootnote(
            palette: _palette,
            text: 'Kirim = citra beserta koordinat dan waktu observasi diunggah ke '
                'server ${ReportConfig.serverHost} untuk ditinjau kurator. '
                'Jangan kirim = citra tetap di perangkat Anda dan dihapus saat '
                'keluar dari halaman ini.',
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neonLime.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.neonLime.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.help_outline, size: 14, color: AppColors.neonLime),
          const SizedBox(width: 8),
          Text(
            'SPESIES TIDAK DIKENALI',
            style: ReportSheetText.mono(
              AppColors.neonLime,
              weight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapturedImageCard extends StatelessWidget {
  const _CapturedImageCard({
    required this.palette,
    required this.imagePath,
    required this.title,
    required this.detail,
  });

  final ReportSheetPalette palette;
  final String? imagePath;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final String? path = imagePath;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: path == null
                  ? ColoredBox(color: palette.switchTrackOff)
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: palette.switchTrackOff),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ReportSheetText.sans(
                    palette.title,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: ReportSheetText.mono(palette.muted, size: 10.5, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
