import 'package:flutter/material.dart';

import '../guide_theme.dart';

/// Logo persegi kecil berisi huruf "K".
class GuideLogo extends StatelessWidget {
  const GuideLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: GuideColors.lime,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'K',
        style: GuideText.title().copyWith(
          fontSize: 16,
          height: 1,
          color: GuideColors.onLime,
        ),
      ),
    );
  }
}

/// Kartu ilustrasi dengan garis diagonal, siku bingkai, dan kotak lime
/// sebagai placeholder. Ganti [child] dengan gambar asli bila sudah ada.
class IllustrationCard extends StatelessWidget {
  const IllustrationCard({super.key, required this.height, this.child});

  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double box = (height * 0.42).clamp(56.0, 92.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: GuideColors.card)),
            Positioned.fill(child: CustomPaint(painter: _StripePainter())),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomPaint(painter: _BracketPainter()),
              ),
            ),
            Center(
              child: child ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: box,
                        height: box,
                        decoration: BoxDecoration(
                          color: GuideColors.lime,
                          borderRadius: BorderRadius.circular(box * 0.3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('ILUSTRASI · PLACEHOLDER', style: GuideText.footer()),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = GuideColors.cardStripe
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    const double gap = 22;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = GuideColors.lime.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const double len = 22;

    // Siku kiri atas.
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Siku kanan bawah.
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Indikator halaman: titik aktif memanjang menjadi pil lime.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 26 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? GuideColors.lime : GuideColors.dotInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Tombol utama lime berbentuk pil dengan ikon panah.
class GuidePrimaryButton extends StatelessWidget {
  const GuidePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: GuideColors.lime,
          foregroundColor: GuideColors.onLime,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GuideText.button()),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Satu baris poin pada daftar anjuran (benar atau salah).
class GuideBulletTile extends StatelessWidget {
  const GuideBulletTile({
    super.key,
    required this.text,
    required this.positive,
  });

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              positive ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: positive ? GuideColors.lime : GuideColors.negative,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GuideText.body())),
        ],
      ),
    );
  }
}
