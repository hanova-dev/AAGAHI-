import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/field_report.dart';
import '../../domain/repositories/field_report_repository.dart';
import '../datasources/field_report_local_data_source.dart';

/// Local-only, in this phase: no remote data source, no network policy to
/// arbitrate. The repository layer still exists (rather than the
/// presentation layer touching the data source directly) because
/// converting `CacheException` to `CacheFailure` at this boundary, and
/// nowhere else, is a hard rule for this codebase (CLAUDE.md S3) - not
/// something field reports get to skip just because their policy is thin.
final class FieldReportRepositoryImpl implements FieldReportRepository {
  const FieldReportRepositoryImpl({required FieldReportLocalDataSource local})
      : _local = local;

  final FieldReportLocalDataSource _local;

  @override
  Future<Either<Failure, FieldReport>> save(FieldReport report) async {
    try {
      await _local.insert(report);
      return Right(report);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Stream<int> watchSavedCount() => _local.watchSavedCount();
}
