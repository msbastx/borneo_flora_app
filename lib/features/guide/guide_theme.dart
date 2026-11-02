import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Palet terang halaman panduan (selaras portal).
class GuideColors {
  GuideColors._();

  static const Color background = AppColors.base200;
  static const Color decorCircle = AppColors.emerald50;
  static const Color card = AppColors.base100;
  static const Color cardStripe = AppColors.base300;
  static const Color lime = AppColors.primary;
  static const Color onLime = AppColors.primaryContent;
  static const Color textPrimary = AppColors.baseContent;
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = AppColors.mutedGrey;
  static const Color dotInactive = AppColors.base300;
  static const Color negative = AppColors.mutedGrey;
}

class GuideText {
  GuideText._();

  static TextStyle title() => TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: GuideColors.textPrimary,
      );

  static TextStyle body() => TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: GuideColors.textBody,
      );

  static TextStyle eyebrow() => TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: GuideColors.lime,
      );

  static TextStyle meta() => TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10.5,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w400,
        color: GuideColors.textMuted,
      );

  static TextStyle footer() => TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 9.5,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w400,
        color: GuideColors.textMuted,
      );

  static TextStyle button() => TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GuideColors.onLime,
      );
}
