import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'guide_theme.dart';
import 'widgets/guide_widgets.dart';

/// Data satu poin anjuran pada halaman panduan.
class GuideBullet {
  const GuideBullet(this.text, {required this.positive});

  final String text;
  final bool positive;
}

/// Data satu langkah panduan.
class GuideStep {
  const GuideStep({
    required this.eyebrow,
    required this.title,
    this.body,
    this.bullets = const [],
    this.ctaLabel = 'Lanjut',
  });

  final String eyebrow;
  final String title;
  final String? body;
  final List<GuideBullet> bullets;
  final String ctaLabel;
}

const List<GuideStep> kGuideSteps = [
  GuideStep(
    eyebrow: 'SELAMAT DATANG',
    title: 'Kenali flora Kalimantan dari satu foto',
    body: 'Aplikasi ini mencocokkan citra tumbuhan Anda dengan 84 rekaman '
        'flora dari repositori kalimantanbio.com. Tidak perlu mendaftar, '
        'langsung pakai.',
  ),
  GuideStep(
    eyebrow: 'LANGKAH 1 · AMBIL CITRA',
    title: 'Isi bingkai dengan satu bagian tumbuhan',
    bullets: [
      GuideBullet(
        'Fokus pada satu helai daun atau satu bunga, bukan seluruh pohon.',
        positive: true,
      ),
      GuideBullet(
        'Gunakan cahaya alami, hindari bayangan keras dan latar ramai.',
        positive: true,
      ),
      GuideBullet(
        'Hindari citra buram, terlalu jauh, atau hasil tangkapan layar.',
        positive: false,
      ),
    ],
  ),
  GuideStep(
    eyebrow: 'LANGKAH 2 · BACA HASIL',
    title: 'Persentase itu keyakinan model, bukan kepastian',
    body: 'Di atas 60% hasil cukup dapat dipercaya. Di bawah itu, aplikasi '
        'menandai citra sebagai tidak dikenali. Selalu periksa kandidat lain '
        'sebelum menyimpulkan, dan minta verifikasi kurator untuk keperluan '
        'ilmiah.',
  ),
  GuideStep(
    eyebrow: 'LANGKAH 3 · IKUT BERKONTRIBUSI',
    title: 'Kirim temuan, lengkapi peta sebaran',
    body: 'Setiap identifikasi bisa Anda kirim ke server sebagai catatan '
        'observasi. Aplikasi selalu meminta izin lebih dulu, dan koordinat '
        'spesies endemik dapat disamarkan.',
    ctaLabel: 'Mulai identifikasi',
  ),
];

class CaptureGuideScreen extends StatefulWidget {
  const CaptureGuideScreen({
    super.key,
    this.steps = kGuideSteps,
    this.onFinish,
    this.onSkip,
  });

  final List<GuideStep> steps;

  /// Dipanggil saat tombol terakhir ditekan ("Mulai identifikasi").
  final VoidCallback? onFinish;

  /// Dipanggil saat "LEWATI" ditekan. Bila null, memakai [onFinish].
  final VoidCallback? onSkip;

  @override
  State<CaptureGuideScreen> createState() => _CaptureGuideScreenState();
}

class _CaptureGuideScreenState extends State<CaptureGuideScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onFinish?.call();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => (widget.onSkip ?? widget.onFinish)?.call();

  @override
  Widget build(BuildContext context) {
    final GuideStep current = widget.steps[_index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GuideColors.background,
        body: Stack(
          children: [
            // Lingkaran dekoratif di kanan atas.
            Positioned(
              top: -90,
              right: -110,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  color: GuideColors.decorCircle,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    index: _index,
                    total: widget.steps.length,
                    onSkip: _skip,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.steps.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => _StepPage(step: widget.steps[i]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: PageDots(
                      count: widget.steps.length,
                      index: _index,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: GuidePrimaryButton(
                      label: current.ctaLabel,
                      onPressed: _next,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                    child: Text(
                      'PANDUAN INI BISA DIBUKA LAGI DARI BERANDA',
                      textAlign: TextAlign.center,
                      style: GuideText.footer(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.onSkip,
  });

  final int index;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final String counter =
        '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: Row(
        children: [
          const GuideLogo(),
          const SizedBox(width: 10),
          Text('PANDUAN · $counter', style: GuideText.meta()),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: GuideColors.textBody,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              'LEWATI',
              style: GuideText.meta().copyWith(color: GuideColors.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step});

  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tinggi ilustrasi menyesuaikan ruang agar teks panjang tetap muat.
        final double cardHeight =
            (constraints.maxHeight * 0.36).clamp(130.0, 230.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IllustrationCard(height: cardHeight),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.eyebrow, style: GuideText.eyebrow()),
                    const SizedBox(height: 12),
                    Text(step.title, style: GuideText.title()),
                    const SizedBox(height: 14),
                    if (step.body != null)
                      Text(step.body!, style: GuideText.body()),
                    for (final GuideBullet b in step.bullets)
                      GuideBulletTile(text: b.text, positive: b.positive),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
