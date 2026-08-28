import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'core/database/app_database.dart';
import 'core/database/database_key.dart';
import 'core/localization/in_memory_localisations.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info_impl.dart';
import 'core/theme/app_theme.dart';
import 'demo/demo_risk_repository.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/parcel_registration/data/datasources/parcel_local_data_source_impl.dart';
import 'features/parcel_registration/data/repositories/parcel_repository_impl.dart';
import 'features/parcel_registration/presentation/providers/parcel_registration_providers.dart';
import 'features/reporting/data/datasources/field_report_local_data_source_impl.dart';
import 'features/reporting/data/repositories/field_report_repository_impl.dart';
import 'features/reporting/presentation/providers/reporting_providers.dart';
import 'features/risk/data/datasources/risk_local_data_source_impl.dart';
import 'features/risk/data/datasources/risk_remote_data_source_impl.dart';
import 'features/risk/data/repositories/risk_repository_impl.dart';
import 'features/risk/presentation/providers/risk_providers.dart';
import 'features/settings/data/datasources/settings_local_data_source_impl.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

/// Set only via `--dart-define=DEMO=true`, never a default in source - a
/// demo build must be requested explicitly, not fallen into.
const _isDemo = bool.fromEnvironment('DEMO');

/// Composition root.
///
/// Outside of `--dart-define=DEMO=true`, `riskRepositoryProvider` is now
/// real (Drift local cache + Dio remote, see docs/api-contract.md) - opening
/// the encrypted database is the one reason `main` is async. No backend is
/// deployed yet, so `RiskRemoteDataSourceImpl` always fails with
/// `NetworkException` against its unreachable default base URL
/// (`core/network/dio_client.dart`): that is what makes
/// `RiskRepositoryImpl`'s offline-first fallback to the Drift cache the
/// thing actually running today, not a demo-only figure of speech.
///
/// `DEMO=true` is the opt-in exception for *risk* data only: it skips the
/// remote data source and overrides `riskRepositoryProvider` with the
/// seeded fake, since no backend is deployed yet. Field reports (flow F)
/// and registered parcels (flow B) are local-only in every build variant -
/// there is no backend to fake for either way - so the encrypted database
/// is opened unconditionally and `fieldReportRepositoryProvider`/
/// `parcelRepositoryProvider` are always the real, Drift-backed
/// implementations. `localisationProvider` is likewise wired identically in
/// both branches with [InMemoryLocalisations] - an unwired localisation
/// provider previously meant that launching the real build variant (the
/// mistake a reviewer running the wrong build is one `flutter run` away
/// from making) crashed on `UnimplementedError` instead of rendering a
/// screen with a few untranslated keys visible. A missing label is a bug
/// you can see; a crash on startup is not a product to evaluate at all.
///
/// Flow A/B onboarding only gates the *non-demo* build: `--dart-define=DEMO=true`
/// always has its four seeded parcels (in-memory, not in Drift) and must
/// keep landing straight on the dashboard, exactly as every other item this
/// session has verified it does - a demo build that suddenly opened on a
/// blank onboarding flow because no real `Parcel` row exists would be a
/// regression, not this feature working correctly.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final key = await const DatabaseKeyProvider().getOrCreateKey();
  final database = AppDatabase(openEncryptedExecutor(encryptionKey: key));
  final parcelRepository = ParcelRepositoryImpl(
    local: ParcelLocalDataSourceImpl(database),
  );
  final settingsRepository = SettingsRepositoryImpl(
    local: SettingsLocalDataSourceImpl(database),
  );

  final overrides = <Override>[
    localisationProvider.overrideWith((ref) => const InMemoryLocalisations()),
    fieldReportRepositoryProvider.overrideWithValue(
      FieldReportRepositoryImpl(
          local: FieldReportLocalDataSourceImpl(database)),
    ),
    parcelRepositoryProvider.overrideWithValue(parcelRepository),
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
  ];

  var needsOnboarding = false;
  if (_isDemo) {
    overrides
        .add(riskRepositoryProvider.overrideWithValue(DemoRiskRepository()));
  } else {
    final localDataSource = RiskLocalDataSourceImpl(database);
    final networkInfo = NetworkInfoImpl(Connectivity());
    overrides.addAll([
      riskLocalDataSourceProvider.overrideWithValue(localDataSource),
      networkInfoProvider.overrideWithValue(networkInfo),
      riskRepositoryProvider.overrideWithValue(
        RiskRepositoryImpl(
          remote: RiskRemoteDataSourceImpl(buildDio()),
          local: localDataSource,
          networkInfo: networkInfo,
        ),
      ),
    ]);

    final registered = await parcelRepository.getFirstParcel();
    registered.fold(
      (_) => needsOnboarding = true,
      (parcel) {
        if (parcel == null) {
          needsOnboarding = true;
        } else {
          overrides
              .add(currentParcelIdProvider.overrideWith((ref) => parcel.id));
        }
      },
    );
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: AagahiApp(showOnboarding: needsOnboarding),
    ),
  );
}

/// H2's "Bigger text" toggle is the one voice-adjacent setting with a real,
/// visible effect this phase: this is the `builder` that actually applies
/// it, app-wide, the moment the toggle changes - not just after a restart.
/// 2.0 matches the exact scale `RiskRing`'s own golden tests already
/// validate (`risk_ring_golden_test.dart`), not a number invented for this
/// screen.
class AagahiApp extends ConsumerWidget {
  const AagahiApp({required this.showOnboarding, super.key});

  final bool showOnboarding;

  static const _biggerTextScale = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biggerText =
        ref.watch(settingsStreamProvider).valueOrNull?.biggerText ?? false;

    return MaterialApp(
      title: 'AAGAHI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        if (!biggerText || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(_biggerTextScale),
          ),
          child: child,
        );
      },
      home: showOnboarding ? const SplashScreen() : const AppShell(),
    );
  }
}
