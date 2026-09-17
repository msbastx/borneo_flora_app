import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const FloraApp());
}

class FloraApp extends StatelessWidget {
  const FloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloraHomeScreen(),
    );
  }
}