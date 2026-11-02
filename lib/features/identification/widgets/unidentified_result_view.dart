import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../identification_theme.dart';

/// Layar gagal identifikasi (non-flora / skor di bawah ambang portal).
/// Hanya teks dan tombol kembali.
class UnidentifiedResultView extends StatelessWidget {
  const UnidentifiedResultView({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: IdentColors.cream,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, inset.top > 0 ? 8 : 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Kembali',
                  ),
                ),
                const Spacer(),
                Text(
                  'Tidak dapat diidentifikasi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: IdentColors.textOnLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5C5C5C),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}