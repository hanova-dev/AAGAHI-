import 'dart:io';

import 'package:aagahi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves persistence to disk, not just to memory - and proves the
/// encryption is real, not a `PRAGMA key` line that silently no-ops against
/// a plaintext build (NFR-SEC-002, CLAUDE.md S1).
///
/// Deliberately bypasses `openEncryptedExecutor` (which reads the key from
/// flutter_secure_storage and the file path from path_provider, both
/// platform channels): this test is about Drift/SQLCipher's own on-disk
/// behaviour, so it constructs the `NativeDatabase` directly against a
/// known temp file with a known key.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aagahi_db_test');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AppDatabase openWithKey(String key) => AppDatabase(
        NativeDatabase(
          dbFile,
          setup: (raw) => raw.execute("PRAGMA key = '$key';"),
        ),
      );

  test(
    'a cached assessment survives closing and reopening the database '
    '(simulating an app restart)',
    () async {
      final firstOpen = openWithKey('correct-passphrase');
      await firstOpen.into(firstOpen.riskAssessmentRows).insertOnConflictUpdate(
            RiskAssessmentRowsCompanion.insert(
              parcelId: 'p1',
              assessedOn: DateTime.utc(2026, 8, 23),
              payload: '{"probability":0.71,"riskBand":"warning"}',
            ),
          );
      // Simulates process death: the connection is gone, nothing is held
      // in memory that the next line could be reading from.
      await firstOpen.close();

      final secondOpen = openWithKey('correct-passphrase');
      final row = await (secondOpen.select(secondOpen.riskAssessmentRows)
            ..where((t) => t.parcelId.equals('p1')))
          .getSingleOrNull();
      await secondOpen.close();

      expect(row, isNotNull);
      expect(row!.payload, '{"probability":0.71,"riskBand":"warning"}');
      // isAtSameMomentAs, not ==: SQLite has no timezone concept, so the
      // UTC/local flag on the round-tripped DateTime isn't guaranteed to
      // match the original - only the instant itself is (verified by
      // running this: `==` failed here on the flag while the moment matched).
      expect(row.assessedOn.isAtSameMomentAs(DateTime.utc(2026, 8, 23)), isTrue);
    },
  );

  test(
    'the database cannot be read back with the wrong key - proving the '
    'encryption is real, not a no-op PRAGMA',
    () async {
      final firstOpen = openWithKey('correct-passphrase');
      await firstOpen.into(firstOpen.riskAssessmentRows).insertOnConflictUpdate(
            RiskAssessmentRowsCompanion.insert(
              parcelId: 'p1',
              assessedOn: DateTime.utc(2026, 8, 23),
              payload: '{}',
            ),
          );
      await firstOpen.close();

      final wrongKeyOpen = openWithKey('wrong-passphrase');
      await expectLater(
        () => wrongKeyOpen.select(wrongKeyOpen.riskAssessmentRows).get(),
        throwsA(anything),
      );
      await wrongKeyOpen.close();
    },
  );
}
