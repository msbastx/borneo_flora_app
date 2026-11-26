import 'package:flutter/material.dart';

/// Satu ScaffoldMessenger untuk seluruh aplikasi, agar notifikasi antrean
/// laporan tetap tampil walau pengguna sudah berpindah layar.
abstract final class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    final ScaffoldMessengerState? messenger = key.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ));
  }
}
