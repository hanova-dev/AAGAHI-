import 'package:aagahi/features/parcel_registration/domain/entities/parcel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Parcel build({double areaAcres = 3.5, WaterSource waterSource = WaterSource.canal}) => Parcel(
        id: 'p1',
        areaAcres: areaAcres,
        cropId: 'wheat',
        sowingDate: DateTime.utc(2026, 8, 1),
        waterSource: waterSource,
        soilType: SoilType.loam,
        createdAt: DateTime.utc(2026, 8, 27),
      );

  group('Parcel', () {
    test('rejects a non-positive area', () {
      expect(() => build(areaAcres: 0), throwsA(isA<AssertionError>()));
      expect(() => build(areaAcres: -1), throwsA(isA<AssertionError>()));
    });

    test('isRainFed is true only for WaterSource.rainOnly', () {
      expect(build(waterSource: WaterSource.rainOnly).isRainFed, isTrue);
      expect(build(waterSource: WaterSource.canal).isRainFed, isFalse);
      expect(build(waterSource: WaterSource.tubewell).isRainFed, isFalse);
      expect(build(waterSource: WaterSource.mixed).isRainFed, isFalse);
    });

    test('hasLocation is false when coordinates were never captured', () {
      expect(build().hasLocation, isFalse);
    });

    test('hasLocation is true once both coordinates are set', () {
      final parcel = Parcel(
        id: 'p1',
        areaAcres: 1,
        cropId: 'wheat',
        sowingDate: DateTime.utc(2026, 8, 1),
        waterSource: WaterSource.canal,
        soilType: SoilType.loam,
        createdAt: DateTime.utc(2026, 8, 27),
        latitude: 31.4,
        longitude: 73.1,
      );
      expect(parcel.hasLocation, isTrue);
    });
  });

  group('stageKeyForDays', () {
    test('maps day counts to the coarse growth stages', () {
      expect(stageKeyForDays(0), 'stage.germination');
      expect(stageKeyForDays(20), 'stage.germination');
      expect(stageKeyForDays(21), 'stage.vegetative');
      expect(stageKeyForDays(45), 'stage.vegetative');
      expect(stageKeyForDays(46), 'stage.reproductive');
      expect(stageKeyForDays(90), 'stage.reproductive');
      expect(stageKeyForDays(91), 'stage.maturity');
    });
  });
}
