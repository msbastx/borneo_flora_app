import 'dart:io';

import 'package:flutter/material.dart';

import '../identification_config.dart';
import '../identification_theme.dart';
import '../models/confidence_level.dart';
import '../models/identified_flora.dart';
import 'confidence_card.dart';

/// Bagian gelap di atas layar hasil: bilah atas, citra pengguna,
/// nama spesies, dan kartu keyakinan.
class ResultHeader extends StatelessWidget {
  const ResultHeader({
    super.key,
    required this.top,
    required this.isConfident,
    required this.confidence,
    required this.onBack,
    required this.onShare,
    this.image,
    this.inferenceTime,
  });

  final IdentifiedFlora top;
  final bool isConfident;
  final ConfidenceLevel confidence;
  final File? image;
  final Duration? inferenceTime;
  final VoidCallback onBack;
  final VoidCallback onShare;

  String get _note {
    if (isConfident) {
      return 'Hasil otomatis, bukan penentuan final. Verifikasi ahli '
          'disarankan untuk keperluan ilmiah.';
    }
    final int percent =
        (IdentificationConfig.confidenceThreshold * 100).round();
    return 'Keyakinan di bawah $percent%. Periksa kandidat berikut sebelum '
        'menyimpulkan.';
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final String? caption =
        isConfident ? top.caption : 'PERIKSA KANDIDAT DI BAWAH';

    return Container(
      width: double.infinity,
      color: IdentColors.background,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 28),
      child: Column(
        children: [
          _TopBar(onBack: onBack, onShare: onShare),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserImage(image: image),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AiChip(),
                    const SizedBox(height: 10),
                    Text(
                      isConfident ? top.title : 'Tidak dikenali',
                      style: IdentText.serif(size: 28),
                    ),
                    if (isConfident && top.showsScientificName) ...[
                      const SizedBox(height: 4),
                      Text(
                        top.scientificName,
                        style: IdentText.body(
                          size: 14,
                          color: const Color(0xFFD5DDD7),
                          style: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (caption != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        style: IdentText.label(size: 9.5, spacing: 1.2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ConfidenceCard(
            percentNumber: top.prediction.percentNumber,
            probability: top.prediction.probability,
            level: confidence,
            inferenceTime: inferenceTime,
            note: _note,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.arrow_back,
          label: 'Kembali',
          onTap: onBack,
        ),
        Expanded(
          child: Center(
            child: Text('HASIL IDENTIFIKASI', style: IdentText.label()),
          ),
        ),
        _SquareIconButton(
          icon: Icons.ios_share,
          label: 'Bagikan',
          onTap: onShare,
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _UserImage extends StatelessWidget {
  const _UserImage({this.image});

  final File? image;

  @override
  Widget build(BuildContext context) {
    final File? image = this.image;

    return Container(
      width: 92,
      height: 104,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: IdentColors.heroImage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: image == null
          ? Text(
              'CITRA\nANDA',
              textAlign: TextAlign.center,
              style: IdentText.label(size: 8, spacing: 1),
            )
          : Image.file(
              image,
              width: 92,
              height: 104,
              fit: BoxFit.cover,
              cacheWidth: 300,
            ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: IdentColors.lime.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IdentColors.lime.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: IdentColors.lime),
          const SizedBox(width: 6),
          Text(
            'DIANALISIS OLEH AI',
            style: IdentText.label(
              color: IdentColors.lime,
              size: 9.5,
              weight: FontWeight.w700,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
