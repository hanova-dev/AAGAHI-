import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/risk_assessment.dart';
import '../../domain/repositories/risk_repository.dart';
import '../datasources/risk_local_data_source.dart';
import '../datasources/risk_remote_data_source.dart';

/// Abstraction over connectivity so the repository is testable without a
/// platform channel.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

/// Offline-first repository.
///
/// Policy, in order:
///   1. Read the cache. If it holds a fresh assessment and no refresh was
///      forced, return it and do not touch the network. Rural data is metered
///      (CI-05: 5 MB/month budget).
///   2. Otherwise attempt a remote fetch, cache the result, return it.
///   3. If the network is unavailable or fails, fall back to whatever is
///      cached, however stale. The UI is responsible for labelling the age
///      (FR-SYNC-002) - staleness is surfaced, never hidden.
///   4. If nothing is cached either, return a failure. Never synthesise an
///      assessment.
///
/// The `notScorable` case is propagated as its own failure type rather than
/// as a low-risk assessment. This is the most important line in the class: a
/// fabricated low-risk reading is the failure mode that gets a farmer hurt.
final class RiskRepositoryImpl implements RiskRepository {
  const RiskRepositoryImpl({
    required RiskRemoteDataSource remote,
    required RiskLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  final RiskRemoteDataSource _remote;
  final RiskLocalDataSource _local;
  final NetworkInfo _networkInfo;

  static const Duration _freshFor = Duration(hours: 12);

  @override
  Future<Either<Failure, RiskAssessment>> getLatestAssessment({
    required String parcelId,
    bool forceRefresh = false,
  }) async {
    RiskAssessment? cached;

    try {
      cached = (await _local.readAssessment(parcelId))?.entity;
    } on CacheException catch (error, stack) {
      // A corrupt cache must not block a network fetch.
      developer.log(
        'Cache read failed for parcel $parcelId',
        name: 'RiskRepository',
        error: error,
        stackTrace: stack,
      );
    }

    final cacheIsFresh = cached != null &&
        DateTime.now().toUtc().difference(cached.assessedOn) < _freshFor;

    if (cacheIsFresh && !forceRefresh) {
      return Right(cached);
    }

    if (!await _networkInfo.isConnected) {
      return cached != null ? Right(cached) : const Left(NetworkFailure());
    }

    try {
      final model = await _remote.fetchLatestAssessment(parcelId);
      try {
        await _local.writeAssessment(parcelId, model);
      } on CacheException catch (error, stack) {
        // Persisting is best-effort; the fetched value is still valid for
        // this session.
        developer.log(
          'Cache write failed for parcel $parcelId',
          name: 'RiskRepository',
          error: error,
          stackTrace: stack,
        );
      }
      return Right(model.entity);
    } on NotScorableException catch (error) {
      // Explicitly NOT falling back to a stale cache here. If the server says
      // the cell is unscorable today, showing last week's WARNING as if it
      // were current would be worse than admitting we do not know.
      return Left(NotScorableFailure(reasonKey: error.reasonKey));
    } on AuthException {
      return const Left(AuthFailure());
    } on ServerException catch (error, stack) {
      developer.log(
        'Server error ${error.statusCode} for parcel $parcelId',
        name: 'RiskRepository',
        error: error,
        stackTrace: stack,
      );
      return cached != null
          ? Right(cached)
          : Left(ServerFailure(statusCode: error.statusCode));
    } on NetworkException {
      return cached != null ? Right(cached) : const Left(NetworkFailure());
    } on FormatException catch (error, stack) {
      // A malformed payload is a server bug. Prefer the last known-good value
      // over showing nothing, but never over showing something invented.
      developer.log(
        'Malformed assessment payload for parcel $parcelId',
        name: 'RiskRepository',
        error: error,
        stackTrace: stack,
      );
      return cached != null ? Right(cached) : const Left(ServerFailure());
    }
  }

  @override
  Stream<RiskAssessment> watchAssessment(String parcelId) =>
      _local.watchAssessment(parcelId).map((model) => model.entity);

  @override
  Future<Either<Failure, String>> ensureBriefingCached(
    String assessmentId,
  ) async {
    try {
      final existing = await _local.briefingPath(assessmentId);
      if (existing != null) return Right(existing);

      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }

      final bytes = await _remote.downloadBriefing(assessmentId);
      final path = await _local.writeBriefing(assessmentId, bytes);
      return Right(path);
    } on ServerException catch (error) {
      return Left(ServerFailure(statusCode: error.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
