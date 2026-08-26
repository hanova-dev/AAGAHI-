import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

part 'app_database.g.dart';

/// One row per parcel's most recent cached risk assessment.
///
/// Deliberately not normalised into separate driver/trace tables: nothing
/// queries into those independently of the assessment they belong to, so a
/// join schema would be structure with no consumer. [payload] is the exact
/// JSON `RiskAssessmentModel.toJson()` produces - the model already owns
/// that serialisation contract, and duplicating it field-by-field into
/// Drift columns would be two places that can drift out of sync with each
/// other.
class RiskAssessmentRows extends Table {
  TextColumn get parcelId => text()();
  DateTimeColumn get assessedOn => dateTime()();
  TextColumn get payload => text()();

  @override
  Set<Column> get primaryKey => {parcelId};
}

/// One row per field observation (flow F). [id] is a client-generated UUID,
/// not autoincrement - reports are created offline, so the client must be
/// able to name a row before any server has ever seen it.
///
/// [syncState] is always `LOCAL_ONLY` in this phase: there is no outbox and
/// no upload path (that is a later phase's work, not this one's). The
/// column exists as a string, not a fixed default, because a real sync
/// state machine will add more values later - it is not speculative, it is
/// the one value that state machine currently has.
class FieldReportRows extends Table {
  TextColumn get id => text()();
  TextColumn get parcelId => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get observationType => text()();
  IntColumn get severity => integer()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get syncState => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [RiskAssessmentRows, FieldReportRows])
class AppDatabase extends _$AppDatabase {
  /// [executor] is injected rather than opened internally so tests can point
  /// at a temp file with a fixed key, without going through
  /// flutter_secure_storage or platform channels at all.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(fieldReportRows);
          }
        },
      );
}

/// Opens (or creates) the encrypted database file at [fileName] under the
/// app's support directory, using [encryptionKey] as the SQLCipher
/// passphrase.
///
/// The SQLCipher-capable sqlite3 build is selected at compile time via
/// `hooks.user_defines.sqlite3.source: sqlcipher` in pubspec.yaml, not at
/// runtime - there is no library-loading call to make here. What we do at
/// runtime is verify it actually took effect: a plaintext sqlite3 build
/// accepts `PRAGMA key` as a silent no-op instead of failing, which would
/// turn a misconfigured build into a database that looks encrypted but
/// isn't (exactly the "ignorance rendered as safety" failure CLAUDE.md S1
/// exists to rule out).
QueryExecutor openEncryptedExecutor({
  required String encryptionKey,
  String fileName = 'aagahi.sqlite',
}) {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, fileName));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$encryptionKey';");
        _assertUsingSqlCipher(rawDb);
      },
    );
  });
}

void _assertUsingSqlCipher(Database rawDb) {
  if (rawDb.select('PRAGMA cipher_version;').isEmpty) {
    throw StateError(
      'sqlite3 was built without SQLCipher support - check the '
      'hooks.user_defines.sqlite3.source: sqlcipher entry in pubspec.yaml. '
      'Refusing to open an unencrypted database as if it were encrypted.',
    );
  }
}
