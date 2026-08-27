import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/parcel.dart';

/// The contract the presentation layer and `main.dart`'s first-launch gate
/// depend on. `ParcelRepositoryImpl` (in `data/repositories`) is the only
/// implementation.
abstract interface class ParcelRepository {
  /// The first registered parcel, or null if none exists yet - this is
  /// exactly the question "does onboarding need to run" answers.
  Future<Either<Failure, Parcel?>> getFirstParcel();

  Future<Either<Failure, Parcel>> save(Parcel parcel);
}
