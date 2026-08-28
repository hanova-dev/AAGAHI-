import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Injected at app start in main.dart - real in both demo and non-demo
/// builds, same reasoning as `fieldReportRepositoryProvider`/
/// `parcelRepositoryProvider`: settings are local-only either way.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
      'Override settingsRepositoryProvider at startup'),
);

/// Live settings, watched (not read once) by every H-flow screen and by
/// `AagahiApp`'s text-scale override - a toggle in H2 must be visible
/// immediately, app-wide, not just after a restart.
final settingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);
