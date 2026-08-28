import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required SettingsLocalDataSource local})
      : _local = local;

  final SettingsLocalDataSource _local;

  @override
  Stream<AppSettings> watchSettings() => _local.watch();

  @override
  Future<Either<Failure, AppSettings>> save(AppSettings settings) async {
    try {
      await _local.save(settings);
      return Right(settings);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAllData() async {
    try {
      await _local.wipeAllData();
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
