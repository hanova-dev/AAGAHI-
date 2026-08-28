import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_settings.dart';
import 'settings_local_data_source.dart';

/// The fixed row id - there is exactly one settings row per device, ever.
const _singletonId = 'singleton';

final class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<AppSettings> watch() {
    return (_db.select(_db.appSettingsRows)
          ..where((t) => t.id.equals(_singletonId)))
        .watchSingleOrNull()
        .map((row) => row == null ? AppSettings.defaults : _toEntity(row));
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      await _db.into(_db.appSettingsRows).insertOnConflictUpdate(
            AppSettingsRowsCompanion.insert(
              id: _singletonId,
              phoneNumber: Value(settings.phoneNumber),
              voiceAutoplay: settings.voiceAutoplay,
              voiceSlower: settings.voiceSlower,
              biggerText: settings.biggerText,
              whatsappEnabled: settings.whatsappEnabled,
              appNotificationEnabled: settings.appNotificationEnabled,
              smsEnabled: settings.smsEnabled,
              voiceCallEnabled: settings.voiceCallEnabled,
              quietHoursStart: settings.quietHoursStart,
              quietHoursEnd: settings.quietHoursEnd,
            ),
          );
    } catch (error) {
      throw CacheException('Failed to save settings: $error');
    }
  }

  @override
  Future<void> wipeAllData() async {
    try {
      await _db.wipeAllData();
    } catch (error) {
      throw CacheException('Failed to wipe local data: $error');
    }
  }

  AppSettings _toEntity(AppSettingsRow row) => AppSettings(
        phoneNumber: row.phoneNumber,
        voiceAutoplay: row.voiceAutoplay,
        voiceSlower: row.voiceSlower,
        biggerText: row.biggerText,
        whatsappEnabled: row.whatsappEnabled,
        appNotificationEnabled: row.appNotificationEnabled,
        smsEnabled: row.smsEnabled,
        voiceCallEnabled: row.voiceCallEnabled,
        quietHoursStart: row.quietHoursStart,
        quietHoursEnd: row.quietHoursEnd,
      );
}
