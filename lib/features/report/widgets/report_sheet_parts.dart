import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/report_decision.dart';

/// Warna satu varian popup. Varian gelap untuk citra tidak dikenali,
/// varian terang untuk spesies endemik.
class ReportSheetPalette {
  const ReportSheetPalette({
    required this.background,
    required this.handle,
    required this.title,
    required this.body,
    required this.muted,
    required this.panel,
    required this.panelBorder,
    required this.switchTrackOn,
    required this.switchThumbOn,
    required this.switchTrackOff,
    required this.switchThumbOff,
    required this.secondaryForeground,
    required this.secondaryBorder,
    required this.primaryBackground,
    required this.primaryForeground,
    required this.primaryIcon,
  });

  final Color background;
  final Color handle;
  final Color title;
  final Color body;
  final Color muted;
  final Color panel;
  final Color panelBorder;
  final Color switchTrackOn;
  final Color switchThumbOn;
  final Color switchTrackOff;
  final Color switchThumbOff;
  final Color secondaryForeground;
  final Color secondaryBorder;
  final Color primaryBackground;
  final Color primaryForeground;
  final Color primaryIcon;

  static const ReportSheetPalette dark = ReportSheetPalette(
    background: Color(0xFF14241A),
    handle: Color(0x33FFFFFF),
    title: Colors.white,
    body: Color(0xFFB9C7BC),
    muted: Color(0xFF8DA395),
    panel: Color(0xFF1F3527),
    panelBorder: Colors.transparent,
    switchTrackOn: AppColors.neonLime,
    switchThumbOn: Color(0xFF14241A),
    switchTrackOff: Color(0xFF2E4636),
    switchThumbOff: Color(0xFF8DA395),
    secondaryForeground: Colors.white,
    secondaryBorder: Color(0x33FFFFFF),
    primaryBackground: AppColors.neonLime,
    primaryForeground: Color(0xFF14241A),
    primaryIcon: Color(0xFF14241A),
  );

  static const ReportSheetPalette light = ReportSheetPalette(
    background: Color(0xFFF1EEE5),
    handle: Color(0x33000000),
    title: AppColors.darkGreen,
    body: Color(0xFF3C4A40),
    muted: AppColors.mutedGrey,
    panel: Colors.white,
    panelBorder: Color(0xFFE0DDD5),
    switchTrackOn: AppColors.neonLime,
    switchThumbOn: Color(0xFF14241A),
    switchTrackOff: Color(0xFFD9D5C8),
    switchThumbOff: Colors.white,
    secondaryForeground: AppColors.darkGreen,
    secondaryBorder: Color(0xFFCFCBBE),
    primaryBackground: Color(0xFF14241A),
    primaryForeground: Colors.white,
    primaryIcon: AppColors.neonLime,
  );
}

/// Gaya teks popup: Playfair Display, Plus Jakarta Sans, dan Space Mono.
abstract final class ReportSheetText {
  static TextStyle serif(Color color, {double size = 30}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle sans(
    Color color, {
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    FontStyle? style,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: height,
        fontWeight: weight,
        fontStyle: style,
        color: color,
      );

  static TextStyle mono(
    Color color, {
    double size = 10,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 1.2,
    double height = 1.5,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );
}

/// Menampilkan popup dan mengembalikan pilihan pengguna.
/// Menutup popup tanpa memilih dianggap "Jangan kirim".
Future<ReportDecision> showReportSheet(BuildContext context, Widget sheet) async {
  final ReportDecision? decision = await showModalBottomSheet<ReportDecision>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => sheet,
  );
  return decision ?? const ReportDecision.skip();
}

/// Bingkai popup: sudut atas membulat dan pegangan geser.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.palette, required this.child});

  final ReportSheetPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Saklar dengan warna sesuai palet popup.
class SheetSwitch extends StatelessWidget {
  const SheetSwitch({
    super.key,
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final ReportSheetPalette palette;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.switchTrackOn
            : palette.switchTrackOff,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.switchThumbOn
            : palette.switchThumbOff,
      ),
    );
  }
}

/// Tombol "Jangan kirim" dan "Kirim citra".
class SheetActionButtons extends StatelessWidget {
  const SheetActionButtons({
    super.key,
    required this.palette,
    required this.onSkip,
    required this.onSend,
    this.skipLabel = 'Jangan kirim',
    this.sendLabel = 'Kirim citra',
  });

  final ReportSheetPalette palette;
  final VoidCallback onSkip;
  final VoidCallback onSend;
  final String skipLabel;
  final String sendLabel;

  @override
  Widget build(BuildContext context) {
    final RoundedRectangleBorder shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final TextStyle labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onSkip,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.secondaryForeground,
                side: BorderSide(color: palette.secondaryBorder),
                shape: shape,
                textStyle: labelStyle,
              ),
              child: Text(skipLabel),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onSend,
              icon: Icon(Icons.cloud_upload_outlined, size: 20, color: palette.primaryIcon),
              label: Text(sendLabel),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryBackground,
                foregroundColor: palette.primaryForeground,
                shape: shape,
                textStyle: labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Catatan kecil bergaya mono di bagian bawah popup.
class SheetFootnote extends StatelessWidget {
  const SheetFootnote({super.key, required this.palette, required this.text});

  final ReportSheetPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: ReportSheetText.mono(palette.muted, height: 1.6));
  }
}
