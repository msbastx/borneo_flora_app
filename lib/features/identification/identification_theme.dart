import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Palet warna layar Identifikasi dan Hasil Identifikasi.
class IdentColors {
  IdentColors._();

  // Permukaan gelap
  static const Color background = Color(0xFF14241A);
  static const Color surface = Color(0xFF25332A);
  static const Color viewfinder = Color(0xFF1F3A25);
  static const Color tipBox = Color(0xFF172A1D);
  static const Color thumb = Color(0xFF35473A);
  static const Color heroImage = Color(0xFF26472D);

  // Aksen
  static const Color lime = AppColors.neonLime;
  static const Color onLime = Color(0xFF14241A);
  static const Color amber = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFC62828);

  // Teks di permukaan gelap
  static const Color bodyOnDark = Color(0xFFB9C7BC);
  static const Color mutedOnDark = Color(0xFF8DA395);

  // Permukaan terang
  static const Color cream = Color(0xFFF2EFE6);
  static const Color tabTrack = Color(0xFFE2E0D8);
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFE4E0D4);
  static const Color placeholderTile = Color(0xFFEDF0E6);
  static const Color barTrack = Color(0xFFDEE0D5);
  static const Color hairline = AppColors.divider;

  // Teks di permukaan terang
  static const Color green = Color(0xFF1F5A33);
  static const Color textOnLight = Color(0xFF2B332D);
  static const Color mutedOnLight = AppColors.mutedGrey;
}

/// Gaya teks: Playfair Display (judul), Plus Jakarta Sans (isi),
/// Space Mono (label kecil), sama dengan halaman Panduan.
class IdentText {
  IdentText._();

  static TextStyle label({
    Color color = IdentColors.mutedOnDark,
    double size = 10,
    FontWeight weight = FontWeight.w400,
    double spacing = 1.6,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        letterSpacing: spacing,
        fontWeight: weight,
        color: color,
      );

  static TextStyle serif({
    double size = 28,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w700,
    double height = 1.1,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color,
      );

  static TextStyle body({
    double size = 13.5,
    Color color = IdentColors.textOnLight,
    FontWeight weight = FontWeight.w400,
    double height = 1.55,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: height,
        fontWeight: weight,
        fontStyle: style,
        color: color,
      );
}
