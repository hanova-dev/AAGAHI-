import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/field_report.dart';

/// The contract the presentation layer depends on.
/// `FieldReportRepositoryImpl` (in `data/repositories`) is the only
/// implementation, wired at the composition root in `main.dart`.
abstract interface class FieldReportRepository {
  Future<Either<Failure, FieldReport>> save(FieldReport report);

  /// Total reports saved on this device, for F6's confirmation count - a
  /// real number read back from the database, not a decorative one.
  Stream<int> watchSavedCount();

  /// Every saved report, newest first - G1 (sync status) lists these as
  /// the real content behind "N saved on this phone," not a fabricated
  /// per-item list.
  Stream<List<FieldReport>> watchAll();
}
