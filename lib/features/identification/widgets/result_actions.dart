import 'package:flutter/material.dart';

import '../identification_theme.dart';

/// Dua tombol aksi di bawah header: Simpan dan Minta verifikasi.
class ResultActions extends StatelessWidget {
  const ResultActions({
    super.key,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onRequestVerification,
  });

  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onRequestVerification;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: isSaved ? 'Tersimpan' : 'Simpan',
            icon: isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
            filled: true,
            onTap: onToggleSaved,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Minta verifikasi',
            icon: Icons.verified_outlined,
            filled: false,
            onTap: onRequestVerification,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);

    return Material(
      color: filled ? IdentColors.background : IdentColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled
            ? BorderSide.none
            : const BorderSide(color: IdentColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled ? IdentColors.lime : IdentColors.green,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IdentText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: filled ? Colors.white : IdentColors.green,
                    height: 1.2,
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
