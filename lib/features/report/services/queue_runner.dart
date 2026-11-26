import 'dart:async';

import '../models/report_queue_item.dart';

/// Hasil satu percobaan mengirim laporan.
enum SendOutcomeKind {
  /// Server menerima laporan (201), atau laporan itu sudah pernah diterima (200).
  sent,

  /// Tidak ada jaringan atau server tidak terjangkau. Hentikan putaran ini.
  offline,

  /// Gangguan sementara (5xx, 429, waktu habis). Layak dicoba ulang.
  retryable,

  /// Ditolak server karena isi laporan. Mengulang tidak akan membantu.
  permanent,
}

class SendOutcome {
  const SendOutcome(this.kind, {this.message, this.duplicate = false});

  const SendOutcome.sent({bool duplicate = false})
      : this(SendOutcomeKind.sent, duplicate: duplicate);

  final SendOutcomeKind kind;
  final String? message;
  final bool duplicate;
}

/// Menentukan jenis hasil dari kode status HTTP.
///
/// [connectionError] true bila permintaan tidak pernah sampai ke server.
SendOutcome classifyHttpResult({
  int? statusCode,
  bool connectionError = false,
  bool timedOut = false,
  String? detail,
}) {
  if (connectionError) {
    return const SendOutcome(
      SendOutcomeKind.offline,
      message: 'Jaringan tidak tersedia atau server belum dapat dijangkau.',
    );
  }
  if (timedOut) {
    return const SendOutcome(SendOutcomeKind.retryable, message: 'Waktu tunggu server habis.');
  }
  switch (statusCode) {
    case 200:
      return const SendOutcome.sent(duplicate: true);
    case 201:
      return const SendOutcome.sent();
    case 429:
      return const SendOutcome(
        SendOutcomeKind.retryable,
        message: 'Terlalu banyak permintaan. Laporan dicoba lagi nanti.',
      );
    case 400:
    case 401:
    case 403:
    case 404:
    case 405:
    case 409:
    case 413:
    case 415:
    case 422:
      return SendOutcome(
        SendOutcomeKind.permanent,
        message: 'Ditolak server ($statusCode)${detail == null || detail.isEmpty ? '' : ': $detail'}',
      );
  }
  return SendOutcome(
    SendOutcomeKind.retryable,
    message: 'Kegagalan layanan server (${statusCode ?? "tanpa kode"}).',
  );
}

/// Penyimpanan antrean. Implementasi produksi memakai SQLite.
abstract interface class ReportQueueStore {
  /// Item yang tertinggal berstatus SENDING (aplikasi ditutup saat mengirim)
  /// dikembalikan ke PENDING.
  Future<void> recoverInterrupted();

  /// Item PENDING, urut dari yang paling lama dibuat.
  Future<List<ReportQueueItem>> pendingItems();

  Future<int> countPending();

  Future<void> updateStatus(
    String id, {
    required UploadStatus status,
    int? attemptCount,
    String? lastError,
  });
}

abstract interface class ReportSender {
  Future<SendOutcome> send(ReportQueueItem item);
}

/// Ringkasan satu putaran pengiriman, dipakai untuk notifikasi.
class QueueRunResult {
  const QueueRunResult({
    this.sent = const [],
    this.failed = const [],
    this.pendingCount = 0,
    this.stoppedOffline = false,
    this.skippedNoNetwork = false,
  });

  final List<ReportQueueItem> sent;
  final List<ReportQueueItem> failed;

  /// Laporan yang masih menunggu setelah putaran selesai.
  final int pendingCount;

  /// Putaran berhenti di tengah karena jaringan putus.
  final bool stoppedOffline;

  /// Putaran tidak dimulai karena perangkat tidak terhubung ke jaringan.
  final bool skippedNoNetwork;

  bool get isQuiet => sent.isEmpty && failed.isEmpty;
}

/// Mengirim isi antrean satu per satu, sesuai urutan pembuatan (FIFO).
///
/// Aturan:
/// - Hanya satu putaran berjalan pada satu waktu. Panggilan saat putaran
///   berjalan meminta satu putaran tambahan, agar laporan baru tidak tertinggal.
/// - Jika jaringan putus, putaran berhenti dan sisa item tetap PENDING
///   dengan urutan yang sama. Tidak ada item yang dilompati.
/// - Gangguan sementara dicoba ulang beberapa kali dalam satu putaran.
/// - Penolakan server menandai item FAILED agar tidak menghambat item lain.
class QueueRunner {
  QueueRunner({
    required this.store,
    required this.sender,
    Future<bool> Function()? hasNetwork,
    this.maxAttemptsPerRound = 3,
    this.retryDelay = const Duration(seconds: 2),
    Future<void> Function(Duration)? sleep,
  })  : _hasNetwork = hasNetwork ?? (() async => true),
        _sleep = sleep ?? Future<void>.delayed;

  final ReportQueueStore store;
  final ReportSender sender;
  final int maxAttemptsPerRound;
  final Duration retryDelay;
  final Future<bool> Function() _hasNetwork;
  final Future<void> Function(Duration) _sleep;

  bool _running = false;
  bool _runAgain = false;

  bool get isRunning => _running;

  /// Mengembalikan null bila putaran lain sedang berjalan. Putaran itu akan
  /// mengulang sekali lagi dan melaporkan hasil gabungannya.
  Future<QueueRunResult?> run() async {
    if (_running) {
      _runAgain = true;
      return null;
    }
    _running = true;
    final List<ReportQueueItem> sent = [];
    final List<ReportQueueItem> failed = [];
    bool stoppedOffline = false;
    try {
      if (!await _hasNetwork()) {
        return QueueRunResult(
          pendingCount: await store.countPending(),
          skippedNoNetwork: true,
        );
      }
      await store.recoverInterrupted();
      do {
        _runAgain = false;
        for (final ReportQueueItem item in await store.pendingItems()) {
          final SendOutcome outcome = await _sendWithRetry(item);
          switch (outcome.kind) {
            case SendOutcomeKind.sent:
              sent.add(item);
            case SendOutcomeKind.permanent:
              failed.add(item.copyWith(lastError: outcome.message));
            case SendOutcomeKind.offline:
              stoppedOffline = true;
            case SendOutcomeKind.retryable:
              break;
          }
          if (stoppedOffline) break;
        }
      } while (_runAgain && !stoppedOffline);
      return QueueRunResult(
        sent: sent,
        failed: failed,
        pendingCount: await store.countPending(),
        stoppedOffline: stoppedOffline,
      );
    } finally {
      _running = false;
    }
  }

  Future<SendOutcome> _sendWithRetry(ReportQueueItem item) async {
    await store.updateStatus(item.id, status: UploadStatus.sending);
    int attempts = item.attemptCount;
    SendOutcome outcome = const SendOutcome(SendOutcomeKind.retryable);

    for (int round = 1; round <= maxAttemptsPerRound; round++) {
      attempts++;
      try {
        outcome = await sender.send(item);
      } catch (error) {
        outcome = SendOutcome(SendOutcomeKind.retryable, message: error.toString());
      }

      switch (outcome.kind) {
        case SendOutcomeKind.sent:
          await store.updateStatus(item.id,
              status: UploadStatus.sent, attemptCount: attempts, lastError: null);
          return outcome;
        case SendOutcomeKind.permanent:
          await store.updateStatus(item.id,
              status: UploadStatus.failed, attemptCount: attempts, lastError: outcome.message);
          return outcome;
        case SendOutcomeKind.offline:
          await store.updateStatus(item.id,
              status: UploadStatus.pending, attemptCount: attempts, lastError: outcome.message);
          return outcome;
        case SendOutcomeKind.retryable:
          if (round < maxAttemptsPerRound) await _sleep(retryDelay);
      }
    }

    // Gangguan sementara tidak menjadikan item FAILED. Item dicoba lagi pada
    // putaran berikutnya (saat jaringan berubah atau aplikasi dibuka lagi).
    await store.updateStatus(item.id,
        status: UploadStatus.pending,
        attemptCount: attempts,
        lastError: outcome.message ?? 'Belum dapat terhubung ke server.');
    return outcome;
  }
}
