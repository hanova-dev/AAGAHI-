import '../models/risk_assessment_model.dart';

/// The server half of the offline-first contract. Implementations throw the
/// exceptions declared in `core/error/exceptions.dart`; the repository is
/// responsible for translating each one to a `Failure`.
abstract interface class RiskRemoteDataSource {
  /// Throws [NotScorableException] when the server reports the cell as
  /// NOT_SCORABLE, [AuthException] on an expired or invalid session,
  /// [ServerException] on a 5xx or malformed-but-parseable response,
  /// [NetworkException] when the request cannot reach the server, and
  /// [FormatException] when the response body cannot be decoded.
  Future<RiskAssessmentModel> fetchLatestAssessment(String parcelId);

  Future<List<int>> downloadBriefing(String assessmentId);
}
