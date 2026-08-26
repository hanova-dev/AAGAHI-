import 'package:aagahi/features/risk/domain/entities/risk_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RiskAssessment build({
    double probability = 0.68,
    RiskBand band = RiskBand.warning,
    double completeness = 1.0,
    bool degraded = false,
    double ciLower = 0.60,
    double ciUpper = 0.76,
    DateTime? assessedOn,
  }) =>
      RiskAssessment(
        parcelId: 'p1',
        assessedOn: assessedOn ?? DateTime.utc(2026, 8, 21),
        probability: probability,
        band: band,
        horizonDays: 14,
        drivers: const [],
        trace: const [],
        modelVersion: 'v2026.08',
        completenessRatio: completeness,
        confidenceLower: ciLower,
        confidenceUpper: ciUpper,
        usedDegradedInputs: degraded,
        isRainFed: false,
      );

  group('RiskBand', () {
    test('watch and above trigger an alert', () {
      expect(RiskBand.low.triggersAlert, isFalse);
      expect(RiskBand.watch.triggersAlert, isTrue);
      expect(RiskBand.severe.triggersAlert, isTrue);
    });

    test('only warning and above get a spoken briefing', () {
      expect(RiskBand.watch.requiresVoiceBriefing, isFalse);
      expect(RiskBand.warning.requiresVoiceBriefing, isTrue);
    });

    test('rejects an unknown wire value rather than defaulting to low', () {
      // Defaulting here would turn a server-side enum change into a silent
      // "no risk" reading on every device. It must throw.
      expect(() => RiskBand.fromWireValue('unknown'), throwsArgumentError);
    });
  });

  group('staleness', () {
    test('fresh assessment is not stale', () {
      final a = build(assessedOn: DateTime.now().toUtc());
      expect(a.isStaleAsOf(DateTime.now().toUtc()), isFalse);
    });

    test('four-day-old assessment is stale', () {
      final now = DateTime.now().toUtc();
      final a = build(assessedOn: now.subtract(const Duration(days: 4)));
      expect(a.isStaleAsOf(now), isTrue);
    });
  });

  group('confidence', () {
    test('degraded inputs cap confidence at moderate', () {
      final a = build(degraded: true, ciLower: 0.66, ciUpper: 0.70);
      expect(a.confidence, ConfidenceLevel.moderate);
    });

    test('incomplete features cap confidence at moderate', () {
      final a = build(completeness: 0.72, ciLower: 0.66, ciUpper: 0.70);
      expect(a.confidence, ConfidenceLevel.moderate);
    });

    test('narrow interval with full inputs is high', () {
      final a = build(ciLower: 0.66, ciUpper: 0.72);
      expect(a.confidence, ConfidenceLevel.high);
    });
  });

  group('invariants', () {
    test('probability outside 0..1 is rejected', () {
      expect(() => build(probability: 1.4), throwsA(isA<AssertionError>()));
    });

    test('inverted confidence interval is rejected', () {
      expect(
        () => build(ciLower: 0.8, ciUpper: 0.2),
        throwsA(isA<AssertionError>()),
      );
    });

    test('more than three drivers is rejected', () {
      const driver = RiskDriver(
        featureName: 'f',
        contribution: 1,
        direction: DriverDirection.increasesRisk,
        narrativeKey: 'k',
        relativeWeight: 1,
      );
      expect(
        () => RiskAssessment(
          parcelId: 'p1',
          assessedOn: DateTime.utc(2026, 8, 21),
          probability: 0.5,
          band: RiskBand.watch,
          horizonDays: 14,
          drivers: const [driver, driver, driver, driver],
          trace: const [],
          modelVersion: 'v1',
          completenessRatio: 1,
          confidenceLower: 0.4,
          confidenceUpper: 0.6,
          usedDegradedInputs: false,
          isRainFed: false,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
