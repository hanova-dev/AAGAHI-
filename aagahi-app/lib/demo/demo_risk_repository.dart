import 'package:dartz/dartz.dart';

import '../core/error/failures.dart';
import '../features/risk/domain/entities/risk_assessment.dart';
import '../features/risk/domain/repositories/risk_repository.dart';

/// Fixed, hand-authored risk assessment for the demo build
/// (`--dart-define=DEMO=true`), wired in `main.dart` and never reachable
/// without that flag.
///
/// Implements `RiskRepository` directly rather than introducing a separate
/// "demo mode" branch inside the screen or provider - `RiskDashboardScreen`
/// and `RiskAssessmentNotifier` run completely unmodified against this, so
/// what gets demonstrated is the exact code that ships, not a parallel path.
///
/// Scenario: a wheat parcel on canal irrigation, fourteen days into a
/// rate-based drying event that ends in WARNING - the case AAGAHI exists to
/// catch (see aagahi-signal/README.md's rate-of-decline validation chart).
final class DemoRiskRepository implements RiskRepository {
  DemoRiskRepository() : _assessment = _buildScenario();

  final RiskAssessment _assessment;

  @override
  Future<Either<Failure, RiskAssessment>> getLatestAssessment({
    required String parcelId,
    bool forceRefresh = false,
  }) async {
    return Right(_assessment);
  }

  @override
  Stream<RiskAssessment> watchAssessment(String parcelId) {
    // No background sync exists yet (Phase 1) and none is being simulated
    // here - the demo shows one static, already-computed assessment, not a
    // live-updating one.
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, String>> ensureBriefingCached(String assessmentId) async {
    // No audio in this build: there is no server to render a briefing from,
    // and flutter_tts/just_audio are not wired yet (Phase 4). Tapping
    // ListenPill will toggle briefly and do nothing audible, which is
    // honest for what actually exists right now.
    return const Left(NetworkFailure());
  }

  static RiskAssessment _buildScenario() {
    final now = DateTime.now().toUtc();

    // Fourteen days of soil-moisture percentile, drying from a comfortable
    // 82nd percentile to the 27th - a curved rate-of-decline signature
    // (slow, then fast, then levelling as it bottoms out), not a straight
    // line, matching the shape validated in the signal pipeline's chart.
    const percentiles = [
      82.0, 80.0, 77.0, 74.0, 69.0, 61.0, 53.0,
      45.0, 39.0, 34.0, 31.0, 29.0, 28.0, 27.0,
    ];
    final trace = [
      for (var i = 0; i < percentiles.length; i++)
        TracePoint(
          date: now.subtract(Duration(days: percentiles.length - 1 - i)),
          percentile: percentiles[i],
        ),
    ];

    return RiskAssessment(
      parcelId: 'demo-parcel-wheat-01',
      assessedOn: now,
      probability: 0.71,
      band: RiskBand.warning,
      horizonDays: 14,
      drivers: const [
        RiskDriver(
          featureName: 'vpd_anomaly_z',
          contribution: 0.19,
          direction: DriverDirection.increasesRisk,
          narrativeKey: 'driver.evaporativeDemand',
          relativeWeight: 1.0,
        ),
        RiskDriver(
          featureName: 'sm_5day_delta',
          contribution: 0.13,
          direction: DriverDirection.increasesRisk,
          narrativeKey: 'driver.rootZoneDrying',
          relativeWeight: 0.68,
        ),
        RiskDriver(
          featureName: 'precip_deficit_30d',
          contribution: 0.06,
          direction: DriverDirection.increasesRisk,
          narrativeKey: 'driver.rainfallDeficit',
          relativeWeight: 0.32,
        ),
      ],
      trace: trace,
      modelVersion: 'demo-v0',
      completenessRatio: 1.0,
      confidenceLower: 0.58,
      confidenceUpper: 0.81,
      // True even in the demo, not just convenient: SIF is unavailable in
      // Earth Engine, so every real prediction from this project runs in
      // NDVI-degraded mode (config.py's SIF note). The demo should not look
      // more confident than the real pipeline can honestly be.
      usedDegradedInputs: true,
      advisoryTitleKey: 'advisory.irrigateNow',
      advisoryBodyKey: 'advisory.irrigateNow.body',
      voiceBriefingUri: null,
    );
  }
}
