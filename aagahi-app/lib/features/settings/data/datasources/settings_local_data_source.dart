import '../../domain/entities/app_settings.dart';

/// Drift/SQLCipher-backed local storage for the one settings row.
abstract interface class SettingsLocalDataSource {
  Stream<AppSettings> watch();

  Future<void> save(AppSettings settings);

  Future<void> wipeAllData();
}
