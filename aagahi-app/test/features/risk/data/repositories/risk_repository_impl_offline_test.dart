import 'dart:io';

import 'package:aagahi/core/database/app_database.dart';
import 'package:aagahi/core/error/failures.dart';
import 'package:aagahi/features/risk/data/datasources/risk_local_data_source_impl.dart';
import 'package:aagahi/features/risk/data/datasources/risk_remote_data_source.dart';
import 'package:aagahi/features/risk/data/models/risk_assessment_model.dart';
import 'package:aagahi/features/risk/data/repositories/risk_repository_impl.dart';
import 'package:aagahi/features/risk/domain/entities/risk_assessment.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements RiskRemoteDataSource {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

/// Exercises RiskRepositoryImpl's offline-fallback policy against a REAL
/// RiskLocalDataSourceImpl/AppDatabase (a temp-file SQLCipher database, not
/// an in-memory fake of the local layer) - only the remote data source and
/// network check are mocktail doubles, since testing "offline" inherently
/// means there is no real network path to exercise. This is the guard on
/// CLAUDE.md's single most important invariant: a farmer sees the last
/// known-good reading, dated, never a fabricated one.
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late RiskLocalDataSourceImpl local;
  late _MockRemote remote;
  late _MockNetworkInfo networkInfo;
  late RiskRepositoryImpl repository;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aagahi_repo_test');
    db = AppDatabase(
      NativeDatabase(
        File('${tempDir.path}/test.sqlite'),
        setup: (raw) => raw.execute("PRAGMA key = 'test-passphrase';"),
      ),
    );
    local = RiskLocalDataSourceImpl(db);
    remote = _MockRemote();
    networkInfo = _MockNetworkInfo();
    repository = RiskRepositoryImpl(
      remote: remote,
      local: local,
      networkInfo: networkInfo,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  RiskAssessment buildAssessment() => RiskAssessment(
        parcelId: 'p1',
        assessedOn: DateTime.now().toUtc(),
        probability: 0.71,
        band: RiskBand.warning,
        horizonDays: 14,
        drivers: const [],
        trace: const [],
        modelVersion: 'v1',
        completenessRatio: 1.0,
        confidenceLower: 0.6,
        confidenceUpper: 0.8,
        usedDegradedInputs: false,
        isRainFed: false,
      );

  test(
    'forced refresh while offline returns the real cached assessment, '
    'never touching the remote',
    () async {
      final cached = buildAssessment();
      await local.writeAssessment('p1', RiskAssessmentModel(entity: cached));

      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getLatestAssessment(
        parcelId: 'p1',
        forceRefresh: true,
      );

      expect(result, Right<Failure, RiskAssessment>(cached));
      verifyNever(() => remote.fetchLatestAssessment(any()));
    },
  );

  test(
    'offline with nothing cached returns NetworkFailure - never a '
    'fabricated assessment',
    () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getLatestAssessment(
        parcelId: 'never-cached',
        forceRefresh: true,
      );

      expect(result, const Left<Failure, RiskAssessment>(NetworkFailure()));
      verifyNever(() => remote.fetchLatestAssessment(any()));
    },
  );

  test(
    'a fresh cache is served without forcing a refresh or touching '
    'the network at all',
    () async {
      final cached = buildAssessment();
      await local.writeAssessment('p1', RiskAssessmentModel(entity: cached));

      final result = await repository.getLatestAssessment(parcelId: 'p1');

      expect(result, Right<Failure, RiskAssessment>(cached));
      verifyNever(() => networkInfo.isConnected);
      verifyNever(() => remote.fetchLatestAssessment(any()));
    },
  );
}
