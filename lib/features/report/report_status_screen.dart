import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'models/report_queue_item.dart';
import 'repositories/report_queue_repository.dart';
import 'services/queue_runner.dart';

/// Daftar laporan di antrean lokal beserta status pengirimannya.
class ReportStatusScreen extends StatefulWidget {
  const ReportStatusScreen({super.key, ReportQueueRepository? queue}) : _queue = queue;

  final ReportQueueRepository? _queue;

  @override
  State<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends State<ReportStatusScreen> {
  late final ReportQueueRepository _queue = widget._queue ?? ReportQueueRepository.instance;
  StreamSubscription<QueueRunResult>? _sub;
  List<ReportQueueItem> _items = const [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sub = _queue.results.listen((_) => _reload());
    _reload();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final items = await _queue.getAllQueueItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _sendNow() async {
    setState(() => _sending = true);
    await _queue.retryAllFailed();
    final QueueRunResult? result = await _queue.processQueue();
    if (!mounted) return;
    setState(() => _sending = false);
    await _reload();
    if (result?.skippedNoNetwork == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jaringan. Laporan tetap di antrean dan dikirim otomatis saat online.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int waiting = _items.where((i) => i.uploadStatus != UploadStatus.sent).length;
    return Scaffold(
      backgroundColor: AppColors.base200,
      appBar: AppBar(
        title: const Text('Status Laporan'),
        backgroundColor: AppColors.base100,
      ),
      floatingActionButton: waiting == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _sending || _queue.isProcessing ? null : _sendNow,
              icon: _sending
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_sending ? 'Mengirim...' : 'Kirim sekarang ($waiting)'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ReportTile(item: _items[i]),
                  ),
                ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.item});

  final ReportQueueItem item;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (item.uploadStatus) {
      UploadStatus.sent => ('Terkirim', AppColors.emerald700, Icons.check_circle),
      UploadStatus.failed => ('Ditolak server', const Color(0xFFB91C1C), Icons.error),
      UploadStatus.sending => ('Mengirim', const Color(0xFF1D4ED8), Icons.sync),
      UploadStatus.pending => ('Menunggu jaringan', const Color(0xFFB45309), Icons.schedule),
    };
    final File image = File(item.imagePath);
    final String date = _formatDate(item.createdAt.toLocal());

    return Material(
      color: AppColors.base100,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: image.existsSync()
                    ? Image.file(image, fit: BoxFit.cover, cacheWidth: 112)
                    : const ColoredBox(
                        color: AppColors.placeholder,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.reportType.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (item.scientificName != null)
                    Text(item.scientificName!,
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '$date${item.hasCoordinates ? ' · dengan koordinat' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                  ),
                  if (item.uploadStatus != UploadStatus.sent && item.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(item.lastError!,
                          style: TextStyle(fontSize: 12, color: color), maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Belum ada laporan. Laporan yang Anda kirim akan tampil di sini '
          'beserta status pengirimannya.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedGrey),
        ),
      ),
    );
  }
}
