import 'package:dartz/dartz.dart';

import '../core/error/failures.dart';
import '../features/risk/domain/entities/risk_assessment.dart';
import '../features/risk/domain/repositories/risk_repository.dart';

/// One seeded field per demo parcel, keyed by parcel ID - so the C2 parcel
/// switcher (`ParcelSwitcherView`) is a real switch, not a decorative list:
/// picking a different field changes what `RiskDashboardScreen` shows,
/// through the same `riskAssessmentProvider(parcelId)` family provider a
/// real multi-parcel account would use.
///
/// Metadata (name, crop, day) for each parcel lives alongside this class in
/// [demoParcelSummaries] rather than inside [RiskAssessment] itself, since
/// crop/day-of-season is parcel-registration data (Phase elsewhere), not
/// part of a risk assessment.
final class DemoRiskRepository implements RiskRepository {
  DemoRiskRepository() : _assessments = _buildScenarios();

  final Map<String, RiskAssessment> _assessments;

  @override
  Future<Either<Failure, RiskAssessment>> getLatestAssessment({
    required String parcelId,
    bool forceRefresh = false,
  }) async {
    final assessment = _assessments[parcelId];
    if (assessment == null) {
      // A parcelId outside the seeded set - honest absence, not a fabricated
      // reading, same principle as CLAUDE.md S1 applied to demo data.
      return const Left(NetworkFailure());
    }
    return Right(assessment);
  }

  @override
  Stream<RiskAssessment> watchAssessment(String parcelId) {
    // No background sync exists yet (Phase 1) and none is being simulated
    // here - the demo shows static, already-computed assessments, not
    // live-updating ones.
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, String>> ensureBriefingCached(
      String assessmentId) async {
    // No audio in this build: there is no server to render a briefing from,
    // and flutter_tts/just_audio playback is not wired yet (Phase 4). See
    // AlertDetailScreen, which ships its player UI with the file absent on
    // purpose (agreed 2026-08-26) rather than faking a download.
    return const Left(NetworkFailure());
  }

  static Map<String, RiskAssessment> _buildScenarios() {
    final scenarios = [
      _wheatScenario(),
      _mustardScenario(),
      _maizeScenario(),
      _mangoScenario(),
    ];
    return {for (final scenario in scenarios) scenario.parcelId: scenario};
  }

  /// Fourteen days of soil-moisture percentile, drying from a comfortable
  /// 82nd percentile to the 27th - a curved rate-of-decline signature
  /// (slow, then fast, then levelling as it bottoms out), not a straight
  /// line, matching the shape validated in the signal pipeline's chart.
  /// Chak 42/GB, wheat day 24 - the case AAGAHI exists to catch.
  static RiskAssessment _wheatScenario() {
    final now = DateTime.now().toUtc();
    const percentiles = [
      82.0,
      80.0,
      77.0,
      74.0,
      69.0,
      61.0,
      53.0,
      45.0,
      39.0,
      34.0,
      31.0,
      29.0,
      28.0,
      27.0,
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
      trace: _trace(now, percentiles),
      modelVersion: 'demo-v0',
      completenessRatio: 1.0,
      confidenceLower: 0.58,
      confidenceUpper: 0.81,
      // True even in the demo, not just convenient: SIF is unavailable in
      // Earth Engine, so every real prediction from this project runs in
      // NDVI-degraded mode (config.py's SIF note). The demo should not look
      // more confident than the real pipeline can honestly be.
      usedDegradedInputs: true,
      // Rain-fed - D3 ("what to do") shows conservation advice, never
      // irrigation, for exactly this reason (see RiskAssessment.isRainFed).
      isRainFed: true,
      advisoryTitleKey: 'advisory.cutWeedsAndMulch',
      advisoryBodyKey: 'advisory.cutWeedsAndMulch.body',
      voiceBriefingUri: null,
    );
  }

  /// Kotli plot, mustard day 61 - early intensification signal, worth
  /// watching but not yet alert-worthy.
  static RiskAssessment _mustardScenario() {
    final now = DateTime.now().toUtc();
    const percentiles = [58.0, 57.0, 55.0, 54.0, 51.0, 49.0, 47.0];
    return RiskAssessment(
      parcelId: 'demo-parcel-mustard-02',
      assessedOn: now,
      probability: 0.34,
      band: RiskBand.watch,
      horizonDays: 14,
      drivers: const [
        RiskDriver(
          featureName: 'sm_5day_delta',
          contribution: 0.08,
          direction: DriverDirection.increasesRisk,
          narrativeKey: 'driver.rootZoneDrying',
          relativeWeight: 1.0,
        ),
      ],
      trace: _trace(now, percentiles),
      modelVersion: 'demo-v0',
      completenessRatio: 1.0,
      confidenceLower: 0.24,
      confidenceUpper: 0.45,
      usedDegradedInputs: true,
      isRainFed: false,
      advisoryTitleKey: null,
      advisoryBodyKey: null,
      voiceBriefingUri: null,
    );
  }

  /// Nehri rakba, maize day 12 - canal-irrigated, comfortably wet.
  static RiskAssessment _maizeScenario() {
    final now = DateTime.now().toUtc();
    const percentiles = [71.0, 72.0, 70.0, 73.0, 74.0, 72.0, 73.0];
    return RiskAssessment(
      parcelId: 'demo-parcel-maize-03',
      assessedOn: now,
      probability: 0.06,
      band: RiskBand.low,
      horizonDays: 14,
      drivers: const [],
      trace: _trace(now, percentiles),
      modelVersion: 'demo-v0',
      completenessRatio: 1.0,
      confidenceLower: 0.02,
      confidenceUpper: 0.11,
      usedDegradedInputs: false,
      isRainFed: false,
      advisoryTitleKey: null,
      advisoryBodyKey: null,
      voiceBriefingUri: null,
    );
  }

  /// Bagh, mango orchard - perennial tree crop, stable.
  static RiskAssessment _mangoScenario() {
    final now = DateTime.now().toUtc();
    const percentiles = [66.0, 65.0, 67.0, 66.0, 68.0, 67.0, 66.0];
    return RiskAssessment(
      parcelId: 'demo-parcel-mango-04',
      assessedOn: now,
      probability: 0.04,
      band: RiskBand.low,
      horizonDays: 14,
      drivers: const [],
      trace: _trace(now, percentiles),
      modelVersion: 'demo-v0',
      completenessRatio: 1.0,
      confidenceLower: 0.01,
      confidenceUpper: 0.08,
      usedDegradedInputs: false,
      isRainFed: false,
      advisoryTitleKey: null,
      advisoryBodyKey: null,
      voiceBriefingUri: null,
    );
  }

  static List<TracePoint> _trace(DateTime now, List<double> percentiles) => [
        for (var i = 0; i < percentiles.length; i++)
          TracePoint(
            date: now.subtract(Duration(days: percentiles.length - 1 - i)),
            percentile: percentiles[i],
          ),
      ];
}

/// Registration-side metadata for each seeded demo parcel (name, crop,
/// day-of-season) - display-only data for C2's parcel switcher, kept
/// separate from [RiskAssessment] since a real app would source this from
/// parcel registration (Phase elsewhere), not from a risk assessment.
final class DemoParcelSummary {
  const DemoParcelSummary({
    required this.parcelId,
    required this.name,
    required this.cropAndStage,
  });

  final String parcelId;
  final String name;
  final String cropAndStage;
}

const demoParcelSummaries = [
  DemoParcelSummary(
    parcelId: 'demo-parcel-wheat-01',
    name: 'Chak 42/GB',
    cropAndStage: '🌾 Wheat · day 24',
  ),
  DemoParcelSummary(
    parcelId: 'demo-parcel-mustard-02',
    name: 'Kotli plot',
    cropAndStage: '🌻 Mustard · day 61',
  ),
  DemoParcelSummary(
    parcelId: 'demo-parcel-maize-03',
    name: 'Nehri rakba',
    cropAndStage: '🌽 Maize · day 12',
  ),
  DemoParcelSummary(
    parcelId: 'demo-parcel-mango-04',
    name: 'Bagh',
    cropAndStage: '🥭 Mango orchard',
  ),
];
