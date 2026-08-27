import 'package:aagahi/core/error/exceptions.dart';
import 'package:aagahi/core/error/failures.dart';
import 'package:aagahi/features/parcel_registration/data/datasources/parcel_local_data_source.dart';
import 'package:aagahi/features/parcel_registration/data/repositories/parcel_repository_impl.dart';
import 'package:aagahi/features/parcel_registration/domain/entities/parcel.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalDataSource implements ParcelLocalDataSource {
  Parcel? stored;
  bool shouldThrow = false;

  @override
  Future<void> insert(Parcel parcel) async {
    if (shouldThrow) throw const CacheException('disk full');
    stored = parcel;
  }

  @override
  Future<Parcel?> readFirst() async {
    if (shouldThrow) throw const CacheException('disk full');
    return stored;
  }
}

void main() {
  late _FakeLocalDataSource local;
  late ParcelRepositoryImpl repository;

  Parcel buildParcel() => Parcel(
        id: 'p1',
        areaAcres: 3.5,
        cropId: 'wheat',
        sowingDate: DateTime.utc(2026, 8, 1),
        waterSource: WaterSource.rainOnly,
        soilType: SoilType.loam,
        createdAt: DateTime.utc(2026, 8, 27),
      );

  setUp(() {
    local = _FakeLocalDataSource();
    repository = ParcelRepositoryImpl(local: local);
  });

  test('getFirstParcel returns null when nothing is registered yet - this '
      'is exactly what tells main.dart to show onboarding', () async {
    final result = await repository.getFirstParcel();

    expect(result, const Right<Failure, Parcel?>(null));
  });

  test('save writes the parcel and returns it back', () async {
    final parcel = buildParcel();

    final result = await repository.save(parcel);

    expect(result, Right<Failure, Parcel>(parcel));
    expect(local.stored, parcel);
  });

  test('getFirstParcel reflects a real save, not a fabricated value', () async {
    final parcel = buildParcel();
    await repository.save(parcel);

    final result = await repository.getFirstParcel();

    expect(result, Right<Failure, Parcel?>(parcel));
  });

  test('a local failure surfaces as CacheFailure, never a silent drop', () async {
    local.shouldThrow = true;

    final saveResult = await repository.save(buildParcel());
    final readResult = await repository.getFirstParcel();

    expect(saveResult, const Left<Failure, Parcel>(CacheFailure()));
    expect(readResult, const Left<Failure, Parcel?>(CacheFailure()));
  });
}
