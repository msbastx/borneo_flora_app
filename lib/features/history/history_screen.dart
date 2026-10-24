import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/date_label.dart';
import '../../data/history/identification_history_repository.dart';
import '../../data/history/identification_record.dart';
import '../identification/identification_theme.dart';
import '../identification/models/identified_flora.dart';
import '../identification/widgets/pill_tab_bar.dart';
import 'history_controller.dart';
import 'history_detail_screen.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_header.dart';
import 'widgets/history_tile.dart';

/// Layar riwayat identifikasi. Dibuka dari layar Identifikasi lewat Navigator.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    required this.resolve,
  });

  final IdentificationHistoryRepository repository;
  final RecordResolver resolve;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _history;

  @override
  void initState() {
    super.initState();
    _history = HistoryController(widget.repository);
    _history.load();
  }

  @override
  void dispose() {
    _history.dispose();
    super.dispose();
  }

  Future<void> _confirmClear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua riwayat?'),
        content: const Text(
          'Semua hasil identifikasi di perangkat ini akan dihapus. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _history.clear();
  }

  void _delete(IdentificationRecord record) {
    _history.delete(record);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Hasil dihapus'),
          action: SnackBarAction(
            label: 'URUNGKAN',
            onPressed: () => _history.restore(record),
          ),
        ),
      );
  }

  void _open(IdentificationRecord record) {
    final int? id = record.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryDetailScreen(
          recordId: id,
          history: _history,
          resolve: widget.resolve,
        ),
      ),
    );
  }

  /// Menyisipkan label hari (String) di antara baris riwayat.
  List<Object> _withDayLabels(List<IdentificationRecord> records) {
    final List<Object> entries = [];
    String? lastLabel;
    for (final IdentificationRecord record in records) {
      final String label = formatDayLabel(record.capturedAt);
      if (label != lastLabel) {
        entries.add(label);
        lastLabel = label;
      }
      entries.add(record);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: IdentColors.cream,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListenableBuilder(
          listenable: _history,
          builder: (context, _) {
            final List<Object> entries = _withDayLabels(_history.visible);

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HistoryHeader(
                        total: _history.total,
                        savedCount: _history.savedCount,
                        speciesCount: _history.speciesCount,
                        onBack: () => Navigator.of(context).maybePop(),
                        onClear: _history.isEmpty ? null : _confirmClear,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: PillTabBar<HistoryFilter>(
                          values: HistoryFilter.values,
                          selected: _history.filter,
                          labelOf: (f) => f.label,
                          onChanged: _history.setFilter,
                        ),
                      ),
                    ),
                    if (_history.isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 56),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: IdentColors.green,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (entries.isEmpty)
                      SliverToBoxAdapter(
                        child: HistoryEmptyState(filter: _history.filter),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        sliver: SliverList.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, i) =>
                              _buildEntry(context, entries[i]),
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: inset.bottom + 24)),
                  ],
                ),
                // Menjaga area status bar tetap gelap saat daftar digulir.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: inset.top,
                  child: const ColoredBox(color: IdentColors.background),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, Object entry) {
    if (entry is String) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          entry,
          style: IdentText.label(color: IdentColors.mutedOnLight),
        ),
      );
    }

    final IdentificationRecord record = entry as IdentificationRecord;
    final IdentifiedFlora top = widget.resolve(record).first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey<int?>(record.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _delete(record),
        background: const _DeleteBackground(),
        child: HistoryTile(
          record: record,
          top: top,
          onTap: () => _open(record),
          onToggleSaved: () => _history.toggleSaved(record),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: IdentColors.danger,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
