import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/parcel.dart';
import '../../domain/repositories/parcel_repository.dart';

/// Injected at app start in main.dart - real in both demo and non-demo
/// builds, same reasoning as `fieldReportRepositoryProvider`: a registered
/// parcel has no backend to fake, it is local-only either way.
final parcelRepositoryProvider = Provider<ParcelRepository>(
  (ref) =>
      throw UnimplementedError('Override parcelRepositoryProvider at startup'),
);

/// The registered parcel, if any - watched by `RiskDashboardScreen`'s
/// `_ParcelHeader` so a real farmer's field shows its own name/crop/stage
/// instead of the hardcoded demo-parcel lookup in `AppLocalisations`. Null
/// in demo builds and on any device that hasn't finished flow B yet.
final registeredParcelProvider =
    FutureProvider.autoDispose<Parcel?>((ref) async {
  final result = await ref.watch(parcelRepositoryProvider).getFirstParcel();
  return result.fold((_) => null, (parcel) => parcel);
});

/// In-progress answers for the B1-B6 registration wizard. Nothing here is
/// persisted until B7 calls `ParcelRepository.save`.
class ParcelDraft {
  const ParcelDraft({
    this.latitude,
    this.longitude,
    this.areaAcres,
    this.cropId,
    this.sowingDate,
    this.waterSource,
    this.soilType,
  });

  final double? latitude;
  final double? longitude;
  final double? areaAcres;
  final String? cropId;
  final DateTime? sowingDate;
  final WaterSource? waterSource;
  final SoilType? soilType;
}

final parcelDraftProvider =
    NotifierProvider<ParcelDraftNotifier, ParcelDraft>(ParcelDraftNotifier.new);

class ParcelDraftNotifier extends Notifier<ParcelDraft> {
  @override
  ParcelDraft build() => const ParcelDraft();

  void setLocation(double latitude, double longitude) {
    state = ParcelDraft(
      latitude: latitude,
      longitude: longitude,
      areaAcres: state.areaAcres,
      cropId: state.cropId,
      sowingDate: state.sowingDate,
      waterSource: state.waterSource,
      soilType: state.soilType,
    );
  }

  void setArea(double areaAcres) {
    state = ParcelDraft(
      latitude: state.latitude,
      longitude: state.longitude,
      areaAcres: areaAcres,
      cropId: state.cropId,
      sowingDate: state.sowingDate,
      waterSource: state.waterSource,
      soilType: state.soilType,
    );
  }

  void setCrop(String cropId) {
    state = ParcelDraft(
      latitude: state.latitude,
      longitude: state.longitude,
      areaAcres: state.areaAcres,
      cropId: cropId,
      sowingDate: state.sowingDate,
      waterSource: state.waterSource,
      soilType: state.soilType,
    );
  }

  void setSowingDate(DateTime sowingDate) {
    state = ParcelDraft(
      latitude: state.latitude,
      longitude: state.longitude,
      areaAcres: state.areaAcres,
      cropId: state.cropId,
      sowingDate: sowingDate,
      waterSource: state.waterSource,
      soilType: state.soilType,
    );
  }

  void setWaterSource(WaterSource waterSource) {
    state = ParcelDraft(
      latitude: state.latitude,
      longitude: state.longitude,
      areaAcres: state.areaAcres,
      cropId: state.cropId,
      sowingDate: state.sowingDate,
      waterSource: waterSource,
      soilType: state.soilType,
    );
  }

  void setSoilType(SoilType soilType) {
    state = ParcelDraft(
      latitude: state.latitude,
      longitude: state.longitude,
      areaAcres: state.areaAcres,
      cropId: state.cropId,
      sowingDate: state.sowingDate,
      waterSource: state.waterSource,
      soilType: soilType,
    );
  }

  void reset() => state = const ParcelDraft();
}
