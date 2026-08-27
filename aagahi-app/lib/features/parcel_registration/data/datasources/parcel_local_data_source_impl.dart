import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/parcel.dart';
import 'parcel_local_data_source.dart';

final class ParcelLocalDataSourceImpl implements ParcelLocalDataSource {
  ParcelLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Parcel?> readFirst() async {
    try {
      final row =
          await (_db.select(_db.parcelRows)..limit(1)).getSingleOrNull();
      return row == null ? null : _toEntity(row);
    } catch (error) {
      throw CacheException('Failed to read registered parcel: $error');
    }
  }

  @override
  Future<void> insert(Parcel parcel) async {
    try {
      await _db.into(_db.parcelRows).insert(
            ParcelRowsCompanion.insert(
              id: parcel.id,
              areaAcres: parcel.areaAcres,
              cropId: parcel.cropId,
              sowingDate: parcel.sowingDate,
              waterSource: parcel.waterSource.name,
              soilType: parcel.soilType.name,
              createdAt: parcel.createdAt,
              latitude: Value(parcel.latitude),
              longitude: Value(parcel.longitude),
            ),
          );
    } catch (error) {
      throw CacheException('Failed to save parcel ${parcel.id}: $error');
    }
  }

  Parcel _toEntity(ParcelRow row) => Parcel(
        id: row.id,
        areaAcres: row.areaAcres,
        cropId: row.cropId,
        sowingDate: row.sowingDate,
        waterSource: WaterSource.values.byName(row.waterSource),
        soilType: SoilType.values.byName(row.soilType),
        createdAt: row.createdAt,
        latitude: row.latitude,
        longitude: row.longitude,
      );
}
