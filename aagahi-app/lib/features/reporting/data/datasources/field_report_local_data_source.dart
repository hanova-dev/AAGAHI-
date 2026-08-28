import '../../domain/entities/field_report.dart';

/// Drift/SQLCipher-backed local storage for field reports (FR-RPRT, flow
/// F). Kept behind an interface, same as `RiskLocalDataSource`, so the
/// repository and its tests never touch a real database.
abstract interface class FieldReportLocalDataSource {
  Future<void> insert(FieldReport report);

  Stream<int> watchSavedCount();

  Stream<List<FieldReport>> watchAll();
}
