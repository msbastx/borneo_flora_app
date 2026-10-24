import 'package:flutter/material.dart';

import 'core/storage/app_prefs.dart';
import 'app/app_shell.dart';
import 'features/guide/capture_guide_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool seenGuide = await AppPrefs.hasSeenGuide();
  runApp(FloraApp(seenGuide: seenGuide));
}

class FloraApp extends StatelessWidget {
  const FloraApp({super.key, required this.seenGuide});

  final bool seenGuide;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flora Borneo',
      debugShowCheckedModeBanner: false,
      home: seenGuide ? const AppShell() : const _FirstLaunchGuide(),
    );
  }
}

class _FirstLaunchGuide extends StatelessWidget {
  const _FirstLaunchGuide();

  Future<void> _complete(BuildContext context) async {
    await AppPrefs.markGuideSeen();
    if (!context.mounted) return;
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
