import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../identification_theme.dart';

/// Layar gagal identifikasi (non-flora / skor di bawah ambang portal).
/// Berisi penjelasan, tombol kirim foto untuk ditinjau, dan tombol kembali.
class UnidentifiedResultView extends StatelessWidget {
  const UnidentifiedResultView({
    super.key,
    required this.message,
    required this.onBack,
    this.onReport,
  });

  final String message;
  final VoidCallback onBack;

  /// Bila diisi, tampil tombol untuk mengirim foto sebagai flora tidak dikenali.
  final VoidCallback? onReport;

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
                if (onReport != null) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.outbox_outlined),
                    label: const Text('Ini flora? Kirim untuk ditinjau'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Foto hanya dikirim setelah Anda menyetujuinya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
                  ),
                ],
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
