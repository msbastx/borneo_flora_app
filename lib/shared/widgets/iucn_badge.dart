import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Lencana status IUCN berbingkai, contoh `EN` atau `CR`.
class IucnBadge extends StatelessWidget {
  const IucnBadge({super.key, required this.status});

  final String status;

  static Color colorFor(String status) => switch (status) {
        'CR' => const Color(0xFFC62828),
        'EN' => const Color(0xFFE65100),
        'VU' => const Color(0xFF9A6B00),
        'NT' => const Color(0xFF5C7F1E),
        'LC' => const Color(0xFF2E7D32),
        'EW' || 'EX' => const Color(0xFF4E342E),
        _ => AppColors.mutedGrey,
      };

  @override
  Widget build(BuildContext context) {
    final Color color = colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
