import 'package:equatable/equatable.dart';

/// Shared by [Parcel.stageKey] and B4's sowing-date screen, which needs the
/// same mapping before a `Parcel` exists yet (only a candidate sowing date
/// does, in the draft).
String stageKeyForDays(int daysSinceSowing) {
  if (daysSinceSowing <= 20) return 'stage.germination';
  if (daysSinceSowing <= 45) return 'stage.vegetative';
  if (daysSinceSowing <= 90) return 'stage.reproductive';
  return 'stage.maturity';
}

/// Where a parcel's water comes from (screens_v2.html flow B, B5).
///
/// This is the one field this session's demo scenarios and a real
/// registered parcel share meaning for: [isRainFed] on `RiskAssessment`
/// exists for exactly the same reason - see that field's doc comment.
enum WaterSource { rainOnly, canal, tubewell, mixed }

/// B6's squeeze-test categories, plus the honest "we don't know" option the
/// reference itself offers rather than forcing a guess.
enum SoilType { sandy, loam, clay, unknown }

/// A farmer-registered field (screens_v2.html flow B).
///
/// No `name` field: B1-B7 never asks the farmer to type one (the reference
/// mockup's "Chak 42/GB" throughout flow C/E is demo-only content, not
/// something flow B collects) - see [ParcelRepository] and
/// `RiskDashboardScreen`'s `_ParcelHeader` for how a real parcel is labelled
/// instead.
final class Parcel extends Equatable {
  const Parcel({
    required this.id,
    required this.areaAcres,
    required this.cropId,
    required this.sowingDate,
    required this.waterSource,
    required this.soilType,
    required this.createdAt,
    this.latitude,
    this.longitude,
  }) : assert(areaAcres > 0, 'areaAcres must be positive');

  final String id;
  final double areaAcres;

  /// [CropOption.id] from the catalog - not the crop's display name, so a
  /// later localisation or catalog change never has to touch stored rows.
  final String cropId;

  final DateTime sowingDate;
  final WaterSource waterSource;
  final SoilType soilType;
  final DateTime createdAt;

  /// Null when the farmer registered without granting location (A4's
  /// "Not now" is a real, supported path - see CLAUDE.md S1: refusing a
  /// permission is not an error state to paper over with a fabricated
  /// coordinate).
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  /// Rain-fed parcels are never told to irrigate (B5's own banner states
  /// this to the farmer at registration time) - the same rule
  /// `RiskAssessment.isRainFed` and D3 enforce downstream.
  bool get isRainFed => waterSource == WaterSource.rainOnly;

  int daysSinceSowing(DateTime now) => now.difference(sowingDate).inDays;

  /// Localisation key for a coarse, generic growth stage. Not per-crop
  /// agronomy - just enough to answer B4's own "roughly is enough" framing
  /// honestly, for both the draft (before a `Parcel` exists) and the saved
  /// entity - see [stageKeyForDays].
  String stageKey(DateTime now) => stageKeyForDays(daysSinceSowing(now));

  @override
  List<Object?> get props => [
        id,
        areaAcres,
        cropId,
        sowingDate,
        waterSource,
        soilType,
        createdAt,
        latitude,
        longitude,
      ];
}
