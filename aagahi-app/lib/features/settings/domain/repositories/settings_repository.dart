import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_settings.dart';

/// The contract the presentation layer depends on. `SettingsRepositoryImpl`
/// (in `data/repositories`) is the only implementation.
abstract interface class SettingsRepository {
  /// Emits [AppSettings.defaults] immediately if nothing has ever been
  /// saved, then the real row once one exists - H1-H3 and `AagahiApp`'s
  /// text-scale override all watch this rather than reading once.
  Stream<AppSettings> watchSettings();

  Future<Either<Failure, AppSettings>> save(AppSettings settings);

  /// H4's "Delete my account": wipes every table in the local database,
  /// not just settings. There is no server copy to also delete (no
  /// backend exists yet) - this is the entire real effect of that button.
  Future<Either<Failure, Unit>> deleteAllData();
}
