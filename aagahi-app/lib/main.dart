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
import 'features/reporting/data/datasources/field_report_local_data_source_impl.dart';
import 'features/reporting/data/repositories/field_report_repository_impl.dart';
import 'features/reporting/presentation/providers/reporting_providers.dart';
import 'features/risk/data/datasources/risk_local_data_source_impl.dart';
import 'features/risk/data/datasources/risk_remote_data_source_impl.dart';
import 'features/risk/data/repositories/risk_repository_impl.dart';
import 'features/risk/presentation/providers/risk_providers.dart';

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
/// are local-only in every build variant - there is no backend to fake for
/// them either way - so the encrypted database is opened unconditionally
/// and `fieldReportRepositoryProvider` is always the real, Drift-backed
/// implementation. `localisationProvider` is likewise wired identically in
/// both branches with [InMemoryLocalisations] - an unwired localisation
/// provider previously meant that launching the real build variant (the
/// mistake a reviewer running the wrong build is one `flutter run` away
/// from making) crashed on `UnimplementedError` instead of rendering a
/// screen with a few untranslated keys visible. A missing label is a bug
/// you can see; a crash on startup is not a product to evaluate at all.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final key = await const DatabaseKeyProvider().getOrCreateKey();
  final database = AppDatabase(openEncryptedExecutor(encryptionKey: key));

  final overrides = <Override>[
    localisationProvider.overrideWithValue(const InMemoryLocalisations()),
    fieldReportRepositoryProvider.overrideWithValue(
      FieldReportRepositoryImpl(local: FieldReportLocalDataSourceImpl(database)),
    ),
  ];
  if (_isDemo) {
    overrides.add(riskRepositoryProvider.overrideWithValue(DemoRiskRepository()));
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
  }

  runApp(ProviderScope(overrides: overrides, child: const AagahiApp()));
}

class AagahiApp extends StatelessWidget {
  const AagahiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AAGAHI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}
