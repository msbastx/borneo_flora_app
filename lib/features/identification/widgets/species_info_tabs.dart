import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/identified_flora.dart';
import 'pill_tab_bar.dart';

enum _InfoTab {
  summary('RINGKASAN'),
  scientific('ILMIAH'),
  conservation('KONSERVASI');

  const _InfoTab(this.label);

  final String label;
}

/// Tab informasi spesies: Ringkasan, Ilmiah, dan Konservasi.
/// Bidang yang belum ada di katalog tampil sebagai placeholder.
class SpeciesInfoTabs extends StatefulWidget {
  const SpeciesInfoTabs({super.key, required this.flora});

  final IdentifiedFlora flora;

  @override
  State<SpeciesInfoTabs> createState() => _SpeciesInfoTabsState();
}

class _SpeciesInfoTabsState extends State<SpeciesInfoTabs> {
  _InfoTab _tab = _InfoTab.summary;

  Widget _panel() => switch (_tab) {
        _InfoTab.summary => _SummaryPanel(flora: widget.flora),
        _InfoTab.scientific => _ScientificPanel(flora: widget.flora),
        _InfoTab.conservation => _ConservationPanel(flora: widget.flora),
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PillTabBar<_InfoTab>(
          values: _InfoTab.values,
          selected: _tab,
          labelOf: (t) => t.label,
          onChanged: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: 20),
        if (widget.flora.item?.isVerified == false) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6D39B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF805B13), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DATA PENGEMBANGAN: metadata dari server belum diverifikasi. '
                    'Nama umum, taksonomi, dan status konservasi tidak boleh '
                    'dianggap sebagai informasi botani resmi.',
                    style: TextStyle(
                      color: Color(0xFF805B13),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_tab), child: _panel()),
        ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: IdentText.serif(size: 22, color: IdentColors.green));
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: IdentText.body(color: IdentColors.mutedOnLight, height: 1.6),
      );
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.flora});

  final IdentifiedFlora flora;

  @override
  Widget build(BuildContext context) {
    final List<String> paragraphs = flora.item?.description ?? const [];
    final List<String> localNames = flora.item?.localNames ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle('Penjelasan umum'),
        const SizedBox(height: 12),
        if (paragraphs.isEmpty)
          const _MutedText('Deskripsi spesies ini belum tersedia di katalog.')
        else
          for (final String p in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(p, style: IdentText.body(height: 1.6)),
            ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                value: flora.item?.floweringSeason ?? '—',
                caption: 'MUSIM BERBUNGA',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.terrain,
                value: flora.item?.altitude ?? '—',
                caption: 'KETINGGIAN',
              ),
            ),
          ],
        ),
        if (localNames.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'NAMA LOKAL',
            style: IdentText.label(color: IdentColors.mutedOnLight),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final String n in localNames) _NameChip(n)],
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IdentColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IdentColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: IdentColors.green),
          const SizedBox(height: 10),
          Text(
            value,
            style: IdentText.body(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: IdentText.label(
              color: IdentColors.mutedOnLight,
              size: 9,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: IdentColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IdentColors.cardBorder),
      ),
      child: Text(
        name,
        style: IdentText.body(
          size: 12.5,
          weight: FontWeight.w600,
          color: IdentColors.green,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ScientificPanel extends StatelessWidget {
  const _ScientificPanel({required this.flora});

  final IdentifiedFlora flora;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, bool)> rows = [
      ('Nama ilmiah', flora.scientificName, true),
      ('Genus', flora.name.genus, true),
      if (flora.name.epithet.isNotEmpty)
        ('Epitet spesies', flora.name.epithet, true),
      ('Famili', flora.family ?? '—', false),
      if (flora.name.author != null) ('Otoritas', flora.name.author!, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle('Klasifikasi ilmiah'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: IdentColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: IdentColors.cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    color: IdentColors.hairline,
                    height: 1,
                    thickness: 1,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          rows[i].$1.toUpperCase(),
                          style: IdentText.label(
                            color: IdentColors.mutedOnLight,
                            size: 9.5,
                            spacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[i].$2,
                          style: IdentText.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            height: 1.3,
                            style:
                                rows[i].$3 ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConservationPanel extends StatelessWidget {
  const _ConservationPanel({required this.flora});

  final IdentifiedFlora flora;

  @override
  Widget build(BuildContext context) {
    final String? status = flora.item?.conservationStatus;
    final String? note = flora.item?.conservationNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle('Status konservasi'),
        const SizedBox(height: 12),
        if (status == null)
          const _MutedText(
            'Informasi konservasi spesies ini belum tersedia di katalog.',
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: IdentColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: IdentText.label(
                color: IdentColors.lime,
                size: 10,
                weight: FontWeight.w700,
                spacing: 1.2,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(note, style: IdentText.body(height: 1.6)),
          ],
        ],
      ],
    );
  }
}
