import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/risk_assessment.dart';
import '../repositories/risk_repository.dart';

final class GetRiskAssessmentParams extends Equatable {
  const GetRiskAssessmentParams({
    required this.parcelId,
    this.forceRefresh = false,
  });

  final String parcelId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [parcelId, forceRefresh];
}

/// The presentation layer's only path to a risk score. Kept as a thin
/// pass-through today; it exists so a future cross-cutting rule (for example,
/// blocking a forced refresh while an outbox drain is in flight) has one
/// place to live without presentation code reaching into the repository
/// directly.
final class GetRiskAssessment {
  const GetRiskAssessment(this._repository);

  final RiskRepository _repository;

  Future<Either<Failure, RiskAssessment>> call(
    GetRiskAssessmentParams params,
  ) =>
      _repository.getLatestAssessment(
        parcelId: params.parcelId,
        forceRefresh: params.forceRefresh,
      );
}
