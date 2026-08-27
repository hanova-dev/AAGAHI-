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
      expect(
          row.assessedOn.isAtSameMomentAs(DateTime.utc(2026, 8, 23)), isTrue);
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

  // The test above proves SQLCipher is active in-process: it opens a real
  // handle with the right key and a wrong one. That is a runtime-config
  // check, not proof about the artifact - a correctly-keyed handle passes
  // it regardless of what's actually on disk. NFR-SEC-002 is about the
  // file, so this reads the raw bytes directly, with no SQLite API in the
  // path, and checks for the two things that would only be present in a
  // plaintext (or plaintext-header) file.
  const marker = 'PLAINTEXT_CANARY_3f8a9c2b1d7e';
  // SQLite's fixed 16-byte magic string at offset 0 of every unencrypted
  // database file (the newline is literal, the final byte is 0x00).
  const sqliteMagicHeader = 'SQLite format 3\u0000';

  Future<String> writeMarkerAndReadRawFile(String? key) async {
    final db =
        key == null ? AppDatabase(NativeDatabase(dbFile)) : openWithKey(key);
    await db.into(db.riskAssessmentRows).insertOnConflictUpdate(
          RiskAssessmentRowsCompanion.insert(
            parcelId: 'p1',
            assessedOn: DateTime.utc(2026, 8, 23),
            payload: '{"marker":"$marker"}',
          ),
        );
    await db.close();
    final bytes = await dbFile.readAsBytes();
    return String.fromCharCodes(bytes);
  }

  test(
    'sanity check: an UNencrypted database DOES expose the plaintext '
    'payload and the SQLite header in its raw bytes',
    () async {
      // Proves the two assertions below are actually discriminating,
      // rather than being trivially false for an unrelated reason (wrong
      // marker, wrong encoding, reading the wrong file).
      final content = await writeMarkerAndReadRawFile(null);
      expect(content.contains(marker), isTrue);
      expect(content.contains(sqliteMagicHeader), isTrue);
    },
  );

  test(
    'the raw on-disk bytes of an encrypted database contain neither the '
    'plaintext payload nor the standard SQLite header - proving the '
    'encryption is real at the file level, not just checked at open()',
    () async {
      final content = await writeMarkerAndReadRawFile('correct-passphrase');

      expect(
        content.contains(marker),
        isFalse,
        reason:
            'the plaintext payload must not appear anywhere in the file bytes',
      );
      expect(
        content.contains(sqliteMagicHeader),
        isFalse,
        reason:
            'an encrypted file must not start with the standard SQLite header',
      );
    },
  );
}
