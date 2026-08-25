import '../models/risk_assessment_model.dart';

/// The server half of the offline-first contract. Implementations throw the
/// exceptions declared in `core/error/exceptions.dart`; the repository is
/// responsible for translating each one to a `Failure`.
///
/// Wire contract: see `docs/api-contract.md`. In short - `GET
/// /v1/parcels/{parcelId}/risk-assessment` returns HTTP 200 either way;
/// not-scorable is a successful response about a valid parcel
/// (`{"scorable": false, "reason_key": "..."}`), never a 4xx, because a
/// proxy or gateway generating an unrelated 4xx must not be misread as
/// "not enough data" (CLAUDE.md §1).
abstract interface class RiskRemoteDataSource {
  /// Throws [NotScorableException] when the server reports the cell as
  /// not scorable, [AuthException] on 401/403, [ServerException] on any
  /// other non-2xx status, [NetworkException] when the request cannot
  /// reach the server at all (including a connect-timeout), and
  /// [FormatException] when a 200 body doesn't match either documented
  /// shape.
  Future<RiskAssessmentModel> fetchLatestAssessment(String parcelId);

  Future<List<int>> downloadBriefing(String assessmentId);
}
