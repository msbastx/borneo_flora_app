import 'package:flutter/material.dart';


/// Token warna selaras portal kalimantanbio.com (DaisyUI emerald + base).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color primaryContent = Color(0xFFFFFFFF);

  static const Color base100 = Color(0xFFFFFFFF);
  static const Color base200 = Color(0xFFEFF2F1);
  static const Color base300 = Color(0xFFDDE3E0);
  static const Color baseContent = Color(0xFF1F2937);
  static const Color baseContentMuted = Color(0x8C1F2937);

  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald700 = Color(0xFF047857);

  /// Alias lama — dipetakan ke token portal agar layar lain tetap kompil.
  static const Color darkGreen = baseContent;
  static const Color neonLime = primaryLight;
  static const Color mutedGrey = Color(0xFF6B7280);
  static const Color sage = Color(0xFF6B8B74);
  static const Color cornerBracket = primaryLight;
  static const Color divider = base300;
  static const Color navBackground = base100;
  static const Color placeholder = Color(0xFFF3F4F6);
}

class AppText {
  AppText._();

  static TextStyle inter({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.baseContent,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get monoLabel => inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.mutedGrey,
      );

  static TextStyle get homeTitle => inter(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w800,
        color: AppColors.baseContent,
        letterSpacing: -0.8,
      );

  static TextStyle get homeSubtitle => inter(
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w300,
        color: AppColors.baseContentMuted,
      );

  static TextStyle get sectionLabel => inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.mutedGrey,
      );
}

const LinearGradient portalHeroGradient = LinearGradient(
  colors: [
    AppColors.primary,
    AppColors.accentTeal,
    AppColors.primaryLight,
  ],
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.base200,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryContent,
      surface: AppColors.base100,
      onSurface: AppColors.baseContent,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Inter'),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.base100,
      foregroundColor: AppColors.baseContent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: AppText.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.base300,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
