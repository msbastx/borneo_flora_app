import 'package:flutter/material.dart';

/// Batang progres tipis dengan animasi isi dari kosong ke nilai akhir.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.fillColor,
    required this.trackColor,
    this.height = 8,
  });

  /// Rentang 0.0 sampai 1.0.
  final double value;
  final Color fillColor;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: value.clamp(0.0, 1.0).toDouble(),
          ),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: trackColor)),
              FractionallySizedBox(
                widthFactor: v,
                child: ColoredBox(color: fillColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
