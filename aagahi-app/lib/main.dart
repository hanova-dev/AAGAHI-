import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/database/database_key.dart';
import 'core/network/network_info_impl.dart';
import 'core/theme/app_theme.dart';
import 'demo/demo_localisations.dart';
import 'demo/demo_risk_repository.dart';
import 'features/risk/data/datasources/risk_local_data_source_impl.dart';
import 'features/risk/presentation/providers/risk_providers.dart';
import 'features/risk/presentation/screens/risk_dashboard_screen.dart';

/// Set only via `--dart-define=DEMO=true`, never a default in source - a
/// demo build must be requested explicitly, not fallen into.
const _isDemo = bool.fromEnvironment('DEMO');

/// Composition root.
///
/// Outside of `--dart-define=DEMO=true`, `riskRepositoryProvider` still
/// throws `UnimplementedError`: a real `RiskRepositoryImpl` needs a
/// `RiskRemoteDataSource`, and no backend exists yet (Phase 2+). That is
/// deliberate, not a gap to paper over with a fake remote - a missing
/// dependency should fail loudly at the point of use, not quietly return
/// placeholder data.
///
/// `riskLocalDataSourceProvider` and `networkInfoProvider` ARE real outside
/// demo mode as of Phase 1 (Drift+SQLCipher, connectivity_plus) - opening
/// the encrypted database is the one reason `main` is async now.
///
/// `DEMO=true` is the opt-in exception to all of the above: it skips the
/// database and secure storage entirely and overrides the full repository
/// with the seeded fake.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final overrides = <Override>[];
  if (_isDemo) {
    overrides.addAll([
      riskRepositoryProvider.overrideWithValue(DemoRiskRepository()),
      localisationProvider.overrideWithValue(const DemoLocalisations()),
    ]);
  } else {
    final key = await const DatabaseKeyProvider().getOrCreateKey();
    final database = AppDatabase(openEncryptedExecutor(encryptionKey: key));
    overrides.addAll([
      riskLocalDataSourceProvider.overrideWithValue(
        RiskLocalDataSourceImpl(database),
      ),
      networkInfoProvider.overrideWithValue(
        NetworkInfoImpl(Connectivity()),
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
      home: const RiskDashboardScreen(parcelId: 'demo-parcel'),
    );
  }
}
