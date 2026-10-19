// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/format.dart';
import '../../../lib/core/utils/uuid_v4.dart';
import '../../../lib/features/report/models/report_decision.dart';
import '../../../lib/features/report/models/report_draft.dart';
import '../../../lib/features/report/services/coordinate_approximator.dart';

void main() {
  group('CoordinateApproximator', () {
    test('membulatkan ke grid 0,1 derajat', () {
      final r = CoordinateApproximator.approximate(-1.1023, 116.8412);
      expect(r.latitude, -1.1);
      expect(r.longitude, 116.8);
    });
  });

  group('generateUuidV4', () {
    test('berformat UUID versi 4', () {
      final re = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (var i = 0; i < 50; i++) {
        expect(generateUuidV4(), matches(re));
      }
    });
  });

  group('format', () {
    test('ukuran berkas memakai koma desimal', () {
      expect(formatFileSize(2202009), '2,1 MB');
    });
    test('persen memakai koma desimal', () {
      expect(formatPercent(0.182), '18,2%');
    });
    test('koordinat 4 desimal', () {
      expect(formatCoordinates(-1.1023, 116.8412), '-1.1023, 116.8412');
    });
    test('ekstensi berkas', () {
      expect(fileExtensionLabel('/data/foto.jpg'), 'JPG');
    });
  });

  group('ReportDraft.create', () {
    final captured = DateTime.utc(2026, 10, 18, 1, 41);

    test('temuan endemik membulatkan koordinat bila diminta', () {
      final d = ReportDraft.create(
        type: ReportType.endemicFinding,
        imagePath: 'a.jpg',
        capturedAt: captured,
        decision: const ReportDecision(send: true, approximateLocation: true),
        speciesId: 1,
        latitude: -1.1023,
        longitude: 116.8412,
      );
      expect(d.coordinateMode, CoordinateMode.approximate);
      expect(d.latitude, -1.1);
      expect(d.longitude, 116.8);
      expect(d.toRow()['coordinate_mode'], 'approximate');
      expect(d.toRow()['report_type'], 'endemic_finding');
    });

    test('temuan endemik tanpa spesies ditolak', () {
      expect(
        () => ReportDraft.create(
          type: ReportType.endemicFinding,
          imagePath: 'a.jpg',
          capturedAt: captured,
          decision: const ReportDecision(send: true),
          latitude: -1.1,
          longitude: 116.8,
        ),
        throwsArgumentError,
      );
    });

    test('izin pelatihan hanya berlaku untuk citra tidak dikenali', () {
      final endemic = ReportDraft.create(
        type: ReportType.endemicFinding,
        imagePath: 'a.jpg',
        capturedAt: captured,
        decision: const ReportDecision(send: true, allowTraining: true),
        speciesId: 1,
        latitude: -1.1,
        longitude: 116.8,
      );
      final unknown = ReportDraft.create(
        type: ReportType.unrecognized,
        imagePath: 'b.jpg',
        capturedAt: captured,
        decision: const ReportDecision(send: true, allowTraining: true),
      );
      expect(endemic.toRow()['allow_training'], 0);
      expect(unknown.toRow()['allow_training'], 1);
    });
  });
}
