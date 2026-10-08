import 'dart:io';

import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/identification_source.dart';
import '../models/identification_status.dart';

/// Panel viewfinder. Menampilkan placeholder saat belum ada citra, lalu
/// citra yang dipilih saat diproses. Pesan galat tampil di kotak petunjuk.
class ViewfinderPanel extends StatelessWidget {
  const ViewfinderPanel({
    super.key,
    required this.source,
    required this.status,
    this.image,
    this.errorMessage,
  });

  static const String tip =
      'Isi bingkai dengan satu helai daun, hindari bayangan keras.';

  final IdentificationSource source;
  final IdentificationStatus status;
  final File? image;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final bool busy = status == IdentificationStatus.loadingModel ||
        status == IdentificationStatus.predicting;
    final File? image = this.image;
    final String? error =
        status == IdentificationStatus.failure ? errorMessage : null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: IdentColors.viewfinder,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          if (image != null) ...[
            Positioned.fill(
              child: Image.file(
                image,
                fit: BoxFit.cover,
                // Foto kamera sangat besar, kecilkan saat didekode.
                cacheWidth: 900,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: busy ? 0.45 : 0.15),
              ),
            ),
          ] else
            const Center(child: _FocusCircle()),
          const _Brackets(),
          if (image == null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  source == IdentificationSource.camera
                      ? 'VIEWFINDER · KAMERA'
                      : 'VIEWFINDER · GALERI',
                  style: IdentText.label(size: 9.5, spacing: 1.8),
                ),
              ),
            ),
          if (busy) Center(child: _BusyIndicator(status: status)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _TipBox(message: error ?? tip, isError: error != null),
          ),
        ],
      ),
    );
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator({required this.status});

  final IdentificationStatus status;

  @override
  Widget build(BuildContext context) {
    final String text = status == IdentificationStatus.loadingModel
        ? 'MEMUAT MODEL...'
        : 'MEMPROSES...';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: IdentColors.lime,
          ),
        ),
        const SizedBox(height: 12),
        Text(text, style: IdentText.label(color: Colors.white, size: 10)),
      ],
    );
  }
}

class _TipBox extends StatelessWidget {
  const _TipBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color accent = isError ? IdentColors.amber : IdentColors.lime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: IdentColors.tipBox,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.lightbulb_outline,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: IdentText.body(
                size: 12,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Siku bingkai di empat sudut. Dua atas terang, dua bawah redup.
class _Brackets extends StatelessWidget {
  const _Brackets();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Stack(
          children: [
            _Corner(alignment: Alignment.topLeft, dim: false),
            _Corner(alignment: Alignment.topRight, dim: false),
            _Corner(alignment: Alignment.bottomLeft, dim: true),
            _Corner(alignment: Alignment.bottomRight, dim: true),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment, required this.dim});

  final Alignment alignment;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final bool isTop = alignment.y < 0;
    final bool isLeft = alignment.x < 0;
    final BorderSide side = BorderSide(
      color: IdentColors.lime.withValues(alpha: dim ? 0.3 : 1),
      width: 2,
    );

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 26,
        height: 26,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: isTop ? side : BorderSide.none,
              bottom: !isTop ? side : BorderSide.none,
              left: isLeft ? side : BorderSide.none,
              right: !isLeft ? side : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusCircle extends StatelessWidget {
  const _FocusCircle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(132),
      painter: _DashedCirclePainter(),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Path circle = Path()..addOval(Offset.zero & size);

    for (final metric in circle.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
