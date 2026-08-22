import '../../domain/entities/risk_assessment.dart';

/// Wire/cache representation of [RiskAssessment].
///
/// Kept as an explicit model rather than serialising the entity directly, so
/// a server field rename or a schema-version bump is a change to this file
/// only - the domain entity and its invariants never have to know about JSON.
final class RiskAssessmentModel {
  const RiskAssessmentModel({required this.entity});

  final RiskAssessment entity;

  factory RiskAssessmentModel.fromJson(Map<String, dynamic> json) {
    return RiskAssessmentModel(
      entity: RiskAssessment(
        parcelId: json['parcelId'] as String,
        assessedOn: DateTime.parse(json['assessedOn'] as String).toUtc(),
        probability: (json['probability'] as num).toDouble(),
        band: RiskBand.fromWireValue(json['riskBand'] as String),
        horizonDays: json['horizonDays'] as int,
        drivers: (json['drivers'] as List<dynamic>? ?? const [])
            .map((driver) => _driverFromJson(driver as Map<String, dynamic>))
            .toList(growable: false),
        trace: (json['trace'] as List<dynamic>? ?? const [])
            .map((point) => _tracePointFromJson(point as Map<String, dynamic>))
            .toList(growable: false),
        modelVersion: json['modelVersion'] as String,
        completenessRatio: (json['completenessRatio'] as num).toDouble(),
        confidenceLower: (json['confidenceLower'] as num).toDouble(),
        confidenceUpper: (json['confidenceUpper'] as num).toDouble(),
        usedDegradedInputs: json['usedDegradedInputs'] as bool? ?? false,
        advisoryTitleKey: json['advisoryTitleKey'] as String?,
        advisoryBodyKey: json['advisoryBodyKey'] as String?,
        voiceBriefingUri: json['voiceBriefingUri'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'parcelId': entity.parcelId,
        'assessedOn': entity.assessedOn.toIso8601String(),
        'probability': entity.probability,
        'riskBand': entity.band.wireValue,
        'horizonDays': entity.horizonDays,
        'drivers': entity.drivers
            .map(
              (driver) => {
                'featureName': driver.featureName,
                'contribution': driver.contribution,
                'direction': driver.direction.name,
                'narrativeKey': driver.narrativeKey,
                'relativeWeight': driver.relativeWeight,
              },
            )
            .toList(growable: false),
        'trace': entity.trace
            .map(
              (point) => {
                'date': point.date.toIso8601String(),
                'percentile': point.percentile,
              },
            )
            .toList(growable: false),
        'modelVersion': entity.modelVersion,
        'completenessRatio': entity.completenessRatio,
        'confidenceLower': entity.confidenceLower,
        'confidenceUpper': entity.confidenceUpper,
        'usedDegradedInputs': entity.usedDegradedInputs,
        'advisoryTitleKey': entity.advisoryTitleKey,
        'advisoryBodyKey': entity.advisoryBodyKey,
        'voiceBriefingUri': entity.voiceBriefingUri,
      };

  static RiskDriver _driverFromJson(Map<String, dynamic> json) => RiskDriver(
        featureName: json['featureName'] as String,
        contribution: (json['contribution'] as num).toDouble(),
        direction: json['direction'] == 'decreasesRisk'
            ? DriverDirection.decreasesRisk
            : DriverDirection.increasesRisk,
        narrativeKey: json['narrativeKey'] as String,
        relativeWeight: (json['relativeWeight'] as num).toDouble(),
      );

  static TracePoint _tracePointFromJson(Map<String, dynamic> json) =>
      TracePoint(
        date: DateTime.parse(json['date'] as String).toUtc(),
        percentile: (json['percentile'] as num).toDouble(),
      );
}
