import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/flora_repository.dart';
import '../../data/models/flora_item.dart';

/// Katalog indeks flora yang mengikuti gaya visual halaman Home.
class FloraIndexScreen extends StatefulWidget {
  const FloraIndexScreen({super.key, this.repository});

  final FloraRepository? repository;

  @override
  State<FloraIndexScreen> createState() => _FloraIndexScreenState();
}

class _FloraIndexScreenState extends State<FloraIndexScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<FloraItem> all = (widget.repository ?? FloraRepository()).all;
    final String q = _query.trim().toLowerCase();
    final List<FloraItem> filtered = all.where((item) =>
      item.commonName.toLowerCase().contains(q) ||
      item.scientificName.toLowerCase().contains(q) ||
      item.localNames.any((name) => name.toLowerCase().contains(q))
    ).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INDEKS FLORA', style: AppText.monoLabel),
                  const SizedBox(height: 22),
                  const Text('Kenali kekayaan\nflora Kalimantan',
                      style: AppText.homeTitle),
                  const SizedBox(height: 10),
                  Text('${all.length} spesies dalam katalog saat ini',
                    style: TextStyle(color: AppColors.darkGreen.withValues(alpha: .7))),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari nama lokal atau ilmiah',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .65),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.darkGreen.withValues(alpha: .12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.darkGreen.withValues(alpha: .12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text('DAFTAR SPESIES', style: AppText.monoLabel),
                      const Spacer(),
                      Text('${filtered.length} hasil',
                        style: TextStyle(color: AppColors.darkGreen.withValues(alpha: .65), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('Tidak ada flora yang cocok dengan pencarian.')),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.darkGreen.withValues(alpha: .16))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text(item.index, style: AppText.monoLabel),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.commonName, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                              const SizedBox(height: 4),
                              Text(item.scientificName,
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                              if (item.family != null) ...[
                                const SizedBox(height: 6),
                                Text(item.family!.toUpperCase(),
                                  style: TextStyle(fontSize: 9, letterSpacing: 1.2,
                                    color: AppColors.darkGreen.withValues(alpha: .6))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 100)),
        ],
      ),
    );
  }
}
