import 'package:flutter/material.dart';

/// Token warna yang dipakai bersama oleh banyak layar.
class AppColors {
  AppColors._();

  static const Color darkGreen = Color(0xFF1E3F27);
  static const Color neonLime = Color(0xFFE2F84F);
  static const Color mutedGrey = Color(0xFF7D8379);
  static const Color sage = Color(0xFF6B8B74);
  static const Color cornerBracket = Color(0xFF91C5A0);
  static const Color divider = Color(0xFFE0DDD5);
  static const Color navBackground = Color(0xFF142419);
  static const Color placeholder = Color(0xFFEEEEEE);
}

/// Gaya teks yang dipakai bersama oleh banyak layar.
class AppText {
  AppText._();

  /// Label kecil bergaya mono, contoh "FLORA IDENTIFICATION".
  static const TextStyle monoLabel = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedGrey,
  );

  static const TextStyle homeTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w900,
    color: AppColors.darkGreen,
    letterSpacing: -0.5,
  );
}
