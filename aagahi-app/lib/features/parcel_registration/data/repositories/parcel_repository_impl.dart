import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/parcel.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../datasources/parcel_local_data_source.dart';

final class ParcelRepositoryImpl implements ParcelRepository {
  const ParcelRepositoryImpl({required ParcelLocalDataSource local})
      : _local = local;

  final ParcelLocalDataSource _local;

  @override
  Future<Either<Failure, Parcel?>> getFirstParcel() async {
    try {
      return Right(await _local.readFirst());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Parcel>> save(Parcel parcel) async {
    try {
      await _local.insert(parcel);
      return Right(parcel);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
