import 'package:aagahi/core/error/exceptions.dart';
import 'package:aagahi/core/error/failures.dart';
import 'package:aagahi/features/reporting/data/datasources/field_report_local_data_source.dart';
import 'package:aagahi/features/reporting/data/repositories/field_report_repository_impl.dart';
import 'package:aagahi/features/reporting/domain/entities/field_report.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalDataSource implements FieldReportLocalDataSource {
  final List<FieldReport> inserted = [];
  bool shouldThrow = false;

  @override
  Future<void> insert(FieldReport report) async {
    if (shouldThrow) throw const CacheException('disk full');
    inserted.add(report);
  }

  @override
  Stream<int> watchSavedCount() => Stream.value(inserted.length);
}

void main() {
  late _FakeLocalDataSource local;
  late FieldReportRepositoryImpl repository;

  FieldReport buildReport() => FieldReport(
        id: 'r1',
        parcelId: 'p1',
        observationType: ObservationType.cropWilting,
        severity: 3,
        createdAt: DateTime.utc(2026, 8, 26),
        syncState: SyncState.localOnly,
      );

  setUp(() {
    local = _FakeLocalDataSource();
    repository = FieldReportRepositoryImpl(local: local);
  });

  test('save writes the report locally and returns it back', () async {
    final report = buildReport();

    final result = await repository.save(report);

    expect(result, Right<Failure, FieldReport>(report));
    expect(local.inserted, [report]);
  });

  test('a local write failure surfaces as CacheFailure, never a silent drop', () async {
    local.shouldThrow = true;

    final result = await repository.save(buildReport());

    expect(result, const Left<Failure, FieldReport>(CacheFailure()));
    expect(local.inserted, isEmpty);
  });

  test('watchSavedCount reflects real inserts, not a fabricated number', () async {
    await repository.save(buildReport());

    expect(await repository.watchSavedCount().first, 1);
  });
}
