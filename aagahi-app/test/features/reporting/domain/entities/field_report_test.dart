import 'package:aagahi/features/reporting/domain/entities/field_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FieldReport build({int severity = 3}) => FieldReport(
        id: 'r1',
        parcelId: 'p1',
        observationType: ObservationType.cropWilting,
        severity: severity,
        createdAt: DateTime.utc(2026, 8, 26),
        syncState: SyncState.localOnly,
      );

  group('FieldReport', () {
    test('accepts severity at the 1..5 boundaries', () {
      expect(() => build(severity: 1), returnsNormally);
      expect(() => build(severity: 5), returnsNormally);
    });

    test('rejects severity outside 1..5', () {
      expect(() => build(severity: 0), throwsA(isA<AssertionError>()));
      expect(() => build(severity: 6), throwsA(isA<AssertionError>()));
    });
  });

  group('SyncState', () {
    test('localOnly has the LOCAL_ONLY wire value', () {
      expect(SyncState.localOnly.wireValue, 'LOCAL_ONLY');
    });
  });
}
