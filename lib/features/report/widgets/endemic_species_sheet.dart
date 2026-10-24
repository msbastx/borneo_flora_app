import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/iucn_badge.dart';
import '../models/report_decision.dart';
import '../report_config.dart';
import 'report_sheet_parts.dart';

/// Popup untuk spesies endemik. Pengguna memilih apakah temuan dikirim
/// dan apakah koordinatnya disamarkan terlebih dahulu.
/// Tampilkan dengan `showReportSheet(context, EndemicSpeciesSheet(...))`.
class EndemicSpeciesSheet extends StatefulWidget {
  const EndemicSpeciesSheet({
    super.key,
    required this.commonName,
    required this.scientificName,
    required this.iucnStatus,
    required this.isProtected,
    this.imageUrl,
    this.initialApproximate = true,
  });

  final String commonName;
  final String scientificName;

  /// Kode IUCN, contoh `EN`.
  final String iucnStatus;

  /// True bila `p106` bernilai `Dilindungi`.
  final bool isProtected;

  final String? imageUrl;

  /// Nilai awal saklar samarkan koordinat. Desain Figma menyalakannya.
  final bool initialApproximate;

  @override
  State<EndemicSpeciesSheet> createState() => _EndemicSpeciesSheetState();
}

class _EndemicSpeciesSheetState extends State<EndemicSpeciesSheet> {
  static const ReportSheetPalette _palette = ReportSheetPalette.light;

  late bool _approximate = widget.initialApproximate;

  void _skip() => Navigator.pop(context, const ReportDecision.skip());

  void _send() => Navigator.pop(
        context,
        ReportDecision(send: true, approximateLocation: _approximate),
      );

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      palette: _palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EndemicChip(),
          const SizedBox(height: 16),
          Text(
            widget.isProtected
                ? 'Spesies ini endemik dan dilindungi'
                : 'Spesies ini endemik',
            style: ReportSheetText.serif(_palette.title),
          ),
          const SizedBox(height: 16),
          _SpeciesCard(
            palette: _palette,
            commonName: widget.commonName,
            scientificName: widget.scientificName,
            iucnStatus: widget.iucnStatus,
            imageUrl: widget.imageUrl,
          ),
          const SizedBox(height: 16),
          Text(
            'Titik temuan spesies endemik rawan dimanfaatkan untuk pengambilan '
            'liar. Lokasi presisi hanya dibagikan kepada kurator dan BKSDA, '
            'tidak ditampilkan publik di peta.',
            style: ReportSheetText.sans(_palette.body),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _palette.panel,
              border: Border.all(color: _palette.panelBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SheetSwitch(
                  palette: _palette,
                  value: _approximate,
                  onChanged: (v) => setState(() => _approximate = v),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Samarkan koordinat',
                        style: ReportSheetText.sans(
                          _palette.title,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lokasi dibulatkan ke radius '
                        '${ReportConfig.approximationRadiusKm} km sebelum dikirim.',
                        style: ReportSheetText.sans(_palette.muted, size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SheetActionButtons(palette: _palette, onSkip: _skip, onSend: _send),
          const SizedBox(height: 14),
          SheetFootnote(
            palette: _palette,
            text: 'Kirim = citra dan metadata observasi diunggah ke server '
                '${ReportConfig.serverHost} sebagai catatan sebaran resmi. '
                'Jangan kirim = hasil identifikasi tetap tersimpan lokal di '
                'perangkat Anda saja.',
          ),
        ],
      ),
    );
  }
}

class _EndemicChip extends StatelessWidget {
  const _EndemicChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14241A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: AppColors.neonLime),
          const SizedBox(width: 8),
          Text(
            'FLORA ENDEMIK KALIMANTAN',
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

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({
    required this.palette,
    required this.commonName,
    required this.scientificName,
    required this.iucnStatus,
    required this.imageUrl,
  });

  final ReportSheetPalette palette;
  final String commonName;
  final String scientificName;
  final String iucnStatus;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    final Widget placeholder = ColoredBox(
      color: const Color(0xFFE6E8DD),
      child: Icon(Icons.local_florist_outlined, size: 22, color: palette.muted),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.panelBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: url == null
                  ? placeholder
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                      errorBuilder: (_, __, ___) => placeholder,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commonName,
                  style: ReportSheetText.serif(palette.title, size: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  scientificName,
                  style: ReportSheetText.sans(
                    palette.muted,
                    size: 12,
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IucnBadge(status: iucnStatus),
        ],
      ),
    );
  }
}
