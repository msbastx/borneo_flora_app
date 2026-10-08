import 'package:flutter/material.dart';

import 'core/storage/app_prefs.dart';
import 'app/app_shell.dart';
import 'features/guide/capture_guide_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool seenGuide = await AppPrefs.hasSeenGuide();
  runApp(BiodiversitasBorneoApp(seenGuide: seenGuide));
}

class BiodiversitasBorneoApp extends StatelessWidget {
  const BiodiversitasBorneoApp({super.key, required this.seenGuide});

  final bool seenGuide;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biodiversitas Borneo',
      debugShowCheckedModeBanner: false,
      // Pertahankan theme milik proyekmu di sini.
      home: seenGuide ? const AppShell() : const _FirstLaunchGuide(),
    );
  }
}

/// Menampilkan panduan untuk pengguna baru, lalu pindah ke beranda.
class _FirstLaunchGuide extends StatelessWidget {
  const _FirstLaunchGuide();

  Future<void> _complete(BuildContext context) async {
    await AppPrefs.markGuideSeen();
    if (!context.mounted) return;
    // pushReplacement agar tombol Kembali tidak membuka panduan lagi.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CaptureGuideScreen(
      onFinish: () => _complete(context),
      onSkip: () => _complete(context),
    );
  }
}
