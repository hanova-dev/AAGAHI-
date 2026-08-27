import 'package:drift/drift.dart' show Value;

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
}
