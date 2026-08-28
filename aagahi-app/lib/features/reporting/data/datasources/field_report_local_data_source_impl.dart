import 'package:drift/drift.dart' show OrderingTerm, Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/field_report.dart';
import 'field_report_local_data_source.dart';

final class FieldReportLocalDataSourceImpl
    implements FieldReportLocalDataSource {
  FieldReportLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> insert(FieldReport report) async {
    try {
      await _db.into(_db.fieldReportRows).insert(
            FieldReportRowsCompanion.insert(
              id: report.id,
              parcelId: report.parcelId,
              createdAt: report.createdAt,
              observationType: report.observationType.name,
              severity: report.severity,
              photoPath: Value(report.photoPath),
              syncState: report.syncState.wireValue,
            ),
          );
    } catch (error) {
      throw CacheException('Failed to save field report ${report.id}: $error');
    }
  }

  @override
  Stream<int> watchSavedCount() =>
      _db.select(_db.fieldReportRows).watch().map((rows) => rows.length);

  @override
  Stream<List<FieldReport>> watchAll() {
    return (_db.select(_db.fieldReportRows)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList(growable: false));
  }

  FieldReport _toEntity(FieldReportRow row) => FieldReport(
        id: row.id,
        parcelId: row.parcelId,
        observationType: ObservationType.values.byName(row.observationType),
        severity: row.severity,
        createdAt: row.createdAt,
        // The only wire value ever written today - see SyncState's own
        // doc comment on why there is nothing else to parse yet.
        syncState: SyncState.localOnly,
        photoPath: row.photoPath,
      );
}
