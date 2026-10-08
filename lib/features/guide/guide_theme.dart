import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Palet warna halaman Panduan Pengambilan Citra.
class GuideColors {
  GuideColors._();

  static const Color background = Color(0xFF14241A);
  static const Color decorCircle = Color(0xFF192E21);
  static const Color card = Color(0xFF1A3023);
  static const Color cardStripe = Color(0xFF1E3828);
  static const Color lime = AppColors.neonLime;
  static const Color onLime = Color(0xFF14241A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFFB9C7BC);
  static const Color textMuted = Color(0xFF8DA395);
  static const Color dotInactive = Color(0xFF3B4F42);
  static const Color negative = Color(0xFF8DA395);
}

/// Gaya teks: Playfair Display (judul), Plus Jakarta Sans (isi),
/// Space Mono (label kecil).
class GuideText {
  GuideText._();

  static TextStyle title() => GoogleFonts.playfairDisplay(
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: GuideColors.textPrimary,
      );

  static TextStyle body() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: GuideColors.textBody,
      );

  static TextStyle eyebrow() => GoogleFonts.spaceMono(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: GuideColors.lime,
      );

  static TextStyle meta() => GoogleFonts.spaceMono(
        fontSize: 10.5,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w400,
        color: GuideColors.textMuted,
      );

  static TextStyle footer() => GoogleFonts.spaceMono(
        fontSize: 9.5,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w400,
        color: GuideColors.textMuted,
      );

  static TextStyle button() => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GuideColors.onLime,
      );
}
