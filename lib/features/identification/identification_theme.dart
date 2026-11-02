import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Palet terang untuk identifikasi (bacaan di luar ruangan).
class IdentColors {
  IdentColors._();

  static const Color background = AppColors.base200;
  static const Color surface = AppColors.base100;
  static const Color viewfinder = AppColors.base100;
  static const Color tipBox = AppColors.emerald50;
  static const Color thumb = AppColors.base300;
  static const Color heroImage = AppColors.base200;

  static const Color lime = AppColors.primary;
  static const Color onLime = AppColors.primaryContent;
  static const Color amber = Color(0xFFD97706);
  static const Color danger = Color(0xFFC62828);

  /// Nama lama; sekarang teks di latar terang.
  static const Color bodyOnDark = AppColors.baseContent;
  static const Color mutedOnDark = AppColors.mutedGrey;

  static const Color cream = AppColors.base200;
  static const Color tabTrack = AppColors.base300;
  static const Color card = AppColors.base100;
  static const Color cardBorder = AppColors.base300;
  static const Color placeholderTile = AppColors.placeholder;
  static const Color barTrack = AppColors.base300;
  static const Color hairline = AppColors.divider;

  static const Color green = AppColors.primary;
  static const Color textOnLight = AppColors.baseContent;
  static const Color mutedOnLight = AppColors.mutedGrey;
}

class IdentText {
  IdentText._();

  static TextStyle label({
    Color color = IdentColors.mutedOnLight,
    double size = 10,
    FontWeight weight = FontWeight.w400,
    double spacing = 1.6,
  }) =>
      TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: size,
        letterSpacing: spacing,
        fontWeight: weight,
        color: color,
      );

  static TextStyle serif({
    double size = 28,
    Color color = IdentColors.textOnLight,
    FontWeight weight = FontWeight.w700,
    double height = 1.1,
  }) =>
      TextStyle(
        fontFamily: 'PlayfairDisplay',
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
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: size,
        height: height,
        fontWeight: weight,
        fontStyle: style,
        color: color,
      );
}
