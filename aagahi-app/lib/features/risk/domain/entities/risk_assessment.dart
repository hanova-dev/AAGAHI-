import 'package:equatable/equatable.dart';

/// Risk ladder. Four bands, each rendered with a distinct colour AND a
/// distinct glyph shape AND a distinct word, so meaning survives colour
/// blindness, screen glare, and greyscale (UI-EXT-07, NFR-USE-007).
enum RiskBand {
  low,
  watch,
  warning,
  severe;

  /// Bands at or above this threshold generate an alert (FR-ALRT-001).
  bool get triggersAlert => index >= RiskBand.watch.index;

  /// Bands at or above this threshold get a spoken briefing (FR-ALRT-007).
  bool get requiresVoiceBriefing => index >= RiskBand.warning.index;

  static RiskBand fromWireValue(String value) => switch (value.toLowerCase()) {
        'low' => RiskBand.low,
        'watch' => RiskBand.watch,
        'warning' => RiskBand.warning,
        'severe' => RiskBand.severe,
        _ => throw ArgumentError.value(value, 'value', 'Unknown risk band'),
      };

  String get wireValue => name;
}

/// Direction a driver pushes the prediction.
enum DriverDirection { increasesRisk, decreasesRisk }

/// One contributing cause behind a prediction, derived from a SHAP value.
///
/// The raw SHAP number is retained for audit (FR-EXPL-008) but must never be
/// shown to a farmer-class user (FR-EXPL-007). The UI renders
/// [narrativeKey] and [relativeWeight] instead.
final class RiskDriver extends Equatable {
  const RiskDriver({
    required this.featureName,
    required this.contribution,
    required this.direction,
    required this.narrativeKey,
    required this.relativeWeight,
  }) : assert(
          relativeWeight >= 0.0 && relativeWeight <= 1.0,
          'relativeWeight must be normalised to 0..1',
        );

  /// Model-internal feature name, e.g. `vpd_anomaly_z`. Audit only.
  final String featureName;

  /// Signed SHAP contribution. Audit only.
  final double contribution;

  final DriverDirection direction;

  /// Localisation key for the plain-language cause, e.g.
  /// `driver.evaporativeDemand`. Authored and reviewed by a native Urdu
  /// speaker (FR-EXPL-005), never generated at runtime.
  final String narrativeKey;

  /// |contribution| normalised against the largest driver, for the bar chart.
  final double relativeWeight;

  @override
  List<Object?> get props =>
      [featureName, contribution, direction, narrativeKey, relativeWeight];
}

/// A single point on the soil-moisture percentile trace.
final class TracePoint extends Equatable {
  const TracePoint({required this.date, required this.percentile})
      : assert(
          percentile >= 0.0 && percentile <= 100.0,
          'percentile must be 0..100',
        );

  final DateTime date;
  final double percentile;

  @override
  List<Object?> get props => [date, percentile];
}

/// The system's conclusion for one parcel on one day.
///
/// Note what is deliberately absent: there is no "unknown" or "default" band.
/// If the cell cannot be scored, no `RiskAssessment` is constructed at all -
/// the repository returns `NotScorableFailure` instead. Making the absence of
/// knowledge unrepresentable in this type is what stops a missing reading from
/// ever rendering as low risk.
final class RiskAssessment extends Equatable {
  const RiskAssessment({
    required this.parcelId,
    required this.assessedOn,
    required this.probability,
    required this.band,
    required this.horizonDays,
    required this.drivers,
    required this.trace,
    required this.modelVersion,
    required this.completenessRatio,
    required this.confidenceLower,
    required this.confidenceUpper,
    required this.usedDegradedInputs,
    this.advisoryTitleKey,
    this.advisoryBodyKey,
    this.voiceBriefingUri,
  })  : assert(probability >= 0.0 && probability <= 1.0),
        assert(horizonDays > 0),
        assert(completenessRatio >= 0.0 && completenessRatio <= 1.0),
        assert(confidenceLower <= confidenceUpper),
        assert(drivers.length <= 3, 'At most three drivers are surfaced');

  final String parcelId;
  final DateTime assessedOn;

  /// Calibrated probability of rapid intensification within [horizonDays].
  final double probability;

  final RiskBand band;
  final int horizonDays;

  /// Top drivers, already sorted by descending [RiskDriver.relativeWeight].
  final List<RiskDriver> drivers;

  /// Recent soil-moisture percentile history. Drawn inside the risk ring so
  /// the farmer sees the slope, not just the score - the rate of decline is
  /// the product's whole thesis.
  final List<TracePoint> trace;

  final String modelVersion;

  /// Proportion of required features successfully derived (FR-FEAT-009).
  final double completenessRatio;

  final double confidenceLower;
  final double confidenceUpper;

  /// True when NDVI substituted for SIF, or another fallback was used. Widens
  /// the interval and lowers the reported confidence (FR-INGE-010).
  final bool usedDegradedInputs;

  final String? advisoryTitleKey;
  final String? advisoryBodyKey;

  /// Local file URI of the cached Urdu briefing. Non-null once downloaded, so
  /// it plays offline (FR-SYNC-008).
  final String? voiceBriefingUri;

  /// Age of this assessment. Anything beyond ~3 days must be labelled as stale
  /// in the UI, visually and audibly (FR-SYNC-002).
  Duration ageAsOf(DateTime now) => now.difference(assessedOn);

  bool isStaleAsOf(DateTime now, {Duration threshold = const Duration(days: 3)}) =>
      ageAsOf(now) > threshold;

  /// Qualitative confidence, for display. Never a raw percentage - a farmer
  /// cannot act on "63% confident", but can act on "moderate, two of six
  /// measurements were estimated".
  ConfidenceLevel get confidence {
    if (usedDegradedInputs || completenessRatio < 0.8) {
      return ConfidenceLevel.moderate;
    }
    final width = confidenceUpper - confidenceLower;
    if (width > 0.35) return ConfidenceLevel.moderate;
    if (width > 0.20) return ConfidenceLevel.good;
    return ConfidenceLevel.high;
  }

  @override
  List<Object?> get props => [
        parcelId,
        assessedOn,
        probability,
        band,
        horizonDays,
        drivers,
        trace,
        modelVersion,
        completenessRatio,
        confidenceLower,
        confidenceUpper,
        usedDegradedInputs,
        advisoryTitleKey,
        advisoryBodyKey,
        voiceBriefingUri,
      ];
}

enum ConfidenceLevel { moderate, good, high }
