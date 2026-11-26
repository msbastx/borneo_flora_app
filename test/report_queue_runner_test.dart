import 'package:flutter_test/flutter_test.dart';

import 'package:untitled/features/profile/reporter_profile.dart';
import 'package:untitled/features/report/models/report_queue_item.dart';
import 'package:untitled/features/report/services/queue_runner.dart';

/// Antrean di memori, meniru tabel report_queue.
class MemoryStore implements ReportQueueStore {
  final Map<String, ReportQueueItem> rows = {};
  final List<String> order = [];

  void add(ReportQueueItem item) {
    rows[item.id] = item;
    order.add(item.id);
  }

  UploadStatus status(String id) => rows[id]!.uploadStatus;

  @override
  Future<void> recoverInterrupted() async {
    for (final id in order) {
      if (rows[id]!.uploadStatus == UploadStatus.sending) {
        rows[id] = rows[id]!.copyWith(uploadStatus: UploadStatus.pending);
      }
    }
  }

  @override
  Future<List<ReportQueueItem>> pendingItems() async {
    final items = order
        .map((id) => rows[id]!)
        .where((i) => i.uploadStatus == UploadStatus.pending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<int> countPending() async =>
      rows.values.where((i) => i.uploadStatus == UploadStatus.pending).length;

  @override
  Future<void> updateStatus(String id,
      {required UploadStatus status, int? attemptCount, String? lastError}) async {
    final old = rows[id]!;
    rows[id] = old.copyWith(
      uploadStatus: status,
      attemptCount: attemptCount ?? old.attemptCount,
      lastError: lastError,
    );
  }
}

/// Pengirim palsu. `script` menentukan hasil untuk setiap id, berurutan.
class FakeSender implements ReportSender {
  FakeSender(this.script);
  final Map<String, List<SendOutcome>> script;
  final List<String> calls = [];
  Future<void> Function(String id)? onSend;

  @override
  Future<SendOutcome> send(ReportQueueItem item) async {
    calls.add(item.id);
    await onSend?.call(item.id);
    final list = script[item.id];
    if (list == null || list.isEmpty) return const SendOutcome.sent();
    return list.length == 1 ? list.first : list.removeAt(0);
  }
}

ReportQueueItem item(String id, int minute, {ReportType type = ReportType.unknownImage}) =>
    ReportQueueItem(
      id: id,
      reportType: type,
      imagePath: '/x/$id.jpg',
      createdAt: DateTime.utc(2026, 11, 26, 10, minute),
    );

const offline = SendOutcome(SendOutcomeKind.offline, message: 'offline');
const serverError = SendOutcome(SendOutcomeKind.retryable, message: '503');
const rejected = SendOutcome(SendOutcomeKind.permanent, message: '400');

QueueRunner runner(MemoryStore store, ReportSender sender, {bool network = true}) => QueueRunner(
      store: store,
      sender: sender,
      hasNetwork: () async => network,
      sleep: (_) async {},
    );

void main() {
  group('QueueRunner', () {
    test('mengirim semua laporan sesuai urutan dibuat (FIFO)', () async {
      final store = MemoryStore()
        ..add(item('c', 3))
        ..add(item('a', 1))
        ..add(item('b', 2));
      final sender = FakeSender({});
      final result = (await runner(store, sender).run())!;
      expect(sender.calls, equals(['a', 'b', 'c']));
      expect(result.sent.map((i) => i.id).toList(), equals(['a', 'b', 'c']));
      expect(result.pendingCount, 0);
      for (final id in ['a', 'b', 'c']) {
        expect(store.status(id), UploadStatus.sent);
      }
    });

    test('tanpa jaringan: tidak ada pengiriman, semua tetap PENDING', () async {
      final store = MemoryStore()..add(item('a', 1))..add(item('b', 2));
      final sender = FakeSender({});
      final result = (await runner(store, sender, network: false).run())!;
      expect(sender.calls, isEmpty);
      expect(result.skippedNoNetwork, isTrue);
      expect(result.pendingCount, 2);
    });

    test('jaringan putus di tengah: berhenti, sisa antrean tidak dilompati', () async {
      final store = MemoryStore()
        ..add(item('a', 1))
        ..add(item('b', 2))
        ..add(item('c', 3));
      final sender = FakeSender({'b': [offline]});
      final result = (await runner(store, sender).run())!;
      expect(sender.calls, equals(['a', 'b'])); // c tidak dicoba
      expect(result.stoppedOffline, isTrue);
      expect(store.status('a'), UploadStatus.sent);
      expect(store.status('b'), UploadStatus.pending);
      expect(store.status('c'), UploadStatus.pending);
      expect(result.pendingCount, 2);

      // Saat online kembali, sisa antrean terkirim dengan urutan yang sama.
      final again = FakeSender({});
      await runner(store, again).run();
      expect(again.calls, equals(['b', 'c']));
      expect(store.status('c'), UploadStatus.sent);
    });

    test('banyak laporan dibuat saat offline lalu terkirim berurutan', () async {
      final store = MemoryStore();
      for (var i = 0; i < 5; i++) {
        store.add(item('r$i', i));
      }
      final offlineSender = FakeSender({});
      await runner(store, offlineSender, network: false).run();
      expect(store.rows.values.every((i) => i.uploadStatus == UploadStatus.pending), isTrue);

      final online = FakeSender({});
      final result = (await runner(store, online).run())!;
      expect(online.calls, equals(['r0', 'r1', 'r2', 'r3', 'r4']));
      expect(result.sent.length, 5);
    });

    test('penolakan server menandai FAILED tanpa menahan laporan berikutnya', () async {
      final store = MemoryStore()..add(item('a', 1))..add(item('b', 2));
      final sender = FakeSender({'a': [rejected]});
      final result = (await runner(store, sender).run())!;
      expect(store.status('a'), UploadStatus.failed);
      expect(store.rows['a']!.lastError, '400');
      expect(store.status('b'), UploadStatus.sent);
      expect(result.failed.single.id, 'a');
      expect(sender.calls.where((c) => c == 'a').length, 1); // tidak dicoba ulang
    });

    test('gangguan sementara dicoba ulang lalu berhasil', () async {
      final store = MemoryStore()..add(item('a', 1));
      final sender = FakeSender({'a': [serverError, serverError, const SendOutcome.sent()]});
      await runner(store, sender).run();
      expect(sender.calls, equals(['a', 'a', 'a']));
      expect(store.status('a'), UploadStatus.sent);
      expect(store.rows['a']!.attemptCount, 3);
    });

    test('gangguan sementara terus-menerus: tetap PENDING, bukan FAILED', () async {
      final store = MemoryStore()..add(item('a', 1));
      final sender = FakeSender({'a': [serverError]});
      final result = (await runner(store, sender).run())!;
      expect(store.status('a'), UploadStatus.pending);
      expect(result.pendingCount, 1);
      expect(sender.calls.length, 3);
    });

    test('item SENDING yang terhenti dipulihkan dan dikirim', () async {
      final store = MemoryStore()..add(item('a', 1).copyWith(uploadStatus: UploadStatus.sending));
      final sender = FakeSender({});
      await runner(store, sender).run();
      expect(store.status('a'), UploadStatus.sent);
    });

    test('laporan baru saat putaran berjalan ikut terkirim, tidak dobel', () async {
      final store = MemoryStore()..add(item('a', 1));
      final sender = FakeSender({});
      final r = runner(store, sender);
      sender.onSend = (id) async {
        if (id == 'a') {
          store.add(item('b', 2));
          expect(await r.run(), isNull); // putaran kedua digabung
        }
      };
      final result = (await r.run())!;
      expect(sender.calls, equals(['a', 'b']));
      expect(result.sent.length, 2);
      expect(r.isRunning, isFalse);
    });

    test('balasan 200 (duplikat) dianggap terkirim', () async {
      final store = MemoryStore()..add(item('a', 1));
      final sender = FakeSender({'a': [const SendOutcome.sent(duplicate: true)]});
      await runner(store, sender).run();
      expect(store.status('a'), UploadStatus.sent);
    });

    test('pengecualian dari pengirim diperlakukan sebagai gangguan sementara', () async {
      final store = MemoryStore()..add(item('a', 1));
      final sender = _ThrowingSender();
      await runner(store, sender).run();
      expect(store.status('a'), UploadStatus.pending);
    });
  });

  group('classifyHttpResult', () {
    test('kode status dipetakan dengan benar', () {
      expect(classifyHttpResult(statusCode: 201).kind, SendOutcomeKind.sent);
      expect(classifyHttpResult(statusCode: 200).duplicate, isTrue);
      expect(classifyHttpResult(statusCode: 400).kind, SendOutcomeKind.permanent);
      expect(classifyHttpResult(statusCode: 409).kind, SendOutcomeKind.permanent);
      expect(classifyHttpResult(statusCode: 413).kind, SendOutcomeKind.permanent);
      expect(classifyHttpResult(statusCode: 429).kind, SendOutcomeKind.retryable);
      expect(classifyHttpResult(statusCode: 503).kind, SendOutcomeKind.retryable);
      expect(classifyHttpResult(connectionError: true).kind, SendOutcomeKind.offline);
      expect(classifyHttpResult(timedOut: true).kind, SendOutcomeKind.retryable);
    });
  });

  group('ReportQueueItem.formFields', () {
    test('menyertakan pelapor dan koordinat temuan endemik', () {
      final f = ReportQueueItem(
        id: 'id-1',
        reportType: ReportType.endemicFinding,
        imagePath: 'a.jpg',
        createdAt: DateTime.utc(2026, 11, 26, 2),
        aiKey: 10,
        latitude: -1.2654,
        longitude: 116.8312,
        reporterName: 'Siti',
        reporterEmail: 'siti@example.com',
      ).formFields();
      expect(f['latitude'], '-1.2654');
      expect(f['longitude'], '116.8312');
      expect(f['ai_key'], '10');
      expect(f['reporter_name'], 'Siti');
      expect(f['reporter_email'], 'siti@example.com');
      expect(f['created_at'], '2026-11-26T02:00:00.000Z');
      expect(f.containsKey('scientific_name'), isFalse);
    });

    test('endpoint lama tidak menerima kolom pelapor', () {
      final f = ReportQueueItem(
        id: 'id-2',
        reportType: ReportType.genericSighting,
        imagePath: 'a.jpg',
        createdAt: DateTime.utc(2026),
        scientificName: 'Shorea leprosula',
        reporterName: 'Budi',
        allowTraining: true,
      ).formFields(includeReporter: false);
      expect(f.containsKey('reporter_name'), isFalse);
      expect(f['scientific_name'], 'Shorea leprosula');
      expect(f['allow_training'], 'true');
      expect(f.containsKey('latitude'), isFalse);
    });

    test('endpoint baru dan lama per jenis laporan', () {
      expect(ReportType.unknownImage.endpoint, 'reports/unknown-images/');
      expect(ReportType.endemicFinding.legacyEndpoint, 'findings/');
      expect(ReportType.genericSighting.endpoint, 'reports/sightings/');
      for (final t in ReportType.values) {
        expect(t.endpoint.startsWith('/'), isFalse);
      }
    });

    test('toMap dan fromMap bolak-balik tanpa kehilangan data', () {
      final original = ReportQueueItem(
        id: 'id-3',
        historyId: 4,
        aiKey: 2,
        reportType: ReportType.genericSighting,
        imagePath: 'a.jpg',
        createdAt: DateTime.utc(2026, 1, 2),
        latitude: 1.5,
        longitude: 2.5,
        coordinateApproximate: true,
        allowTraining: true,
        confidence: 0.99,
        modelVersion: 'v2.1',
        scientificName: 'Shorea',
        reporterName: 'A',
        reporterEmail: 'a@b.co',
      );
      final copy = ReportQueueItem.fromMap(original.toMap());
      expect(copy.toMap(), equals(original.toMap()));
    });
  });

  group('ReporterProfile', () {
    test('validasi nama dan email', () {
      expect(ReporterProfile.validateName(''), isNotNull);
      expect(ReporterProfile.validateName('Siti'), isNull);
      expect(ReporterProfile.validateName('x' * 121), isNotNull);
      expect(ReporterProfile.validateEmail(''), isNull);
      expect(ReporterProfile.validateEmail('siti@example.com'), isNull);
      expect(ReporterProfile.validateEmail('siti@'), isNotNull);
      expect(ReporterProfile.validateEmail('siti example.com'), isNotNull);
    });

    test('normalisasi spasi dan huruf email', () {
      final p = const ReporterProfile(name: '  Siti   Aminah ', email: ' Siti@Example.COM ')
          .normalized();
      expect(p.name, 'Siti Aminah');
      expect(p.email, 'siti@example.com');
    });
  });
}

class _ThrowingSender implements ReportSender {
  @override
  Future<SendOutcome> send(ReportQueueItem item) async => throw StateError('boom');
}
