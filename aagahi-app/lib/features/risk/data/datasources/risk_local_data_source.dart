import '../models/risk_assessment_model.dart';

/// The device-local half of the offline-first contract (FR-SYNC-001). The
/// Drift/SQLCipher implementation lives behind this interface so the
/// repository, and every test of it, never touches a real database.
abstract interface class RiskLocalDataSource {
  /// The most recently cached assessment for [parcelId], or null if nothing
  /// has ever been cached.
  Future<RiskAssessmentModel?> readAssessment(String parcelId);

  Future<void> writeAssessment(String parcelId, RiskAssessmentModel model);

  /// Emits whenever a newer assessment is written for [parcelId], including
  /// by a background sync the farmer did not trigger.
  Stream<RiskAssessmentModel> watchAssessment(String parcelId);

  /// Local file path of a cached briefing, or null if it has not been
  /// downloaded yet.
  Future<String?> briefingPath(String assessmentId);

  /// Persists briefing audio and returns its local file path.
  Future<String> writeBriefing(String assessmentId, List<int> bytes);
}
