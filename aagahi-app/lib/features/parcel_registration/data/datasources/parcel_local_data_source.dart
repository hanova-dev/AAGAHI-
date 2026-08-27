import '../../domain/entities/parcel.dart';

/// Drift/SQLCipher-backed local storage for registered parcels.
abstract interface class ParcelLocalDataSource {
  Future<Parcel?> readFirst();

  Future<void> insert(Parcel parcel);
}
