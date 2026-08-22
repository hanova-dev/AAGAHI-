import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/risk_assessment.dart';

/// The contract the presentation layer depends on. `RiskRepositoryImpl`
/// (in `data/repositories`) is the only implementation, wired at the
/// composition root in `main.dart` - domain code never sees Dio, Drift, or
/// connectivity_plus.
abstract interface class RiskRepository {
  Future<Either<Failure, RiskAssessment>> getLatestAssessment({
    required String parcelId,
    bool forceRefresh = false,
  });

  Stream<RiskAssessment> watchAssessment(String parcelId);

  Future<Either<Failure, String>> ensureBriefingCached(String assessmentId);
}
