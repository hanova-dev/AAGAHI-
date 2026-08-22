import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'demo/demo_localisations.dart';
import 'demo/demo_risk_repository.dart';
import 'features/risk/presentation/providers/risk_providers.dart';
import 'features/risk/presentation/screens/risk_dashboard_screen.dart';

/// Set only via `--dart-define=DEMO=true`, never a default in source - a
/// demo build must be requested explicitly, not fallen into.
const _isDemo = bool.fromEnvironment('DEMO');

/// Composition root.
///
/// Outside of `--dart-define=DEMO=true`, wires no provider overrides:
/// `riskRepositoryProvider` and `localisationProvider` (in
/// `risk_providers.dart`) still throw `UnimplementedError` until the local
/// database, network layer, and localisation exist (CLAUDE.md kickoff
/// Phase 1). A fake override there by default would make the app appear to
/// run while hiding exactly how much is unbuilt - a missing dependency
/// should fail loudly at the point of use, not quietly return placeholder
/// data. `DEMO=true` is the one, explicit, opt-in exception: `main.dart`
/// itself is the only place that knows the seeded repository exists, and it
/// is unreachable unless that flag is passed on the command line.
void main() {
  runApp(
    ProviderScope(
      overrides: _isDemo
          ? [
              riskRepositoryProvider.overrideWithValue(DemoRiskRepository()),
              localisationProvider.overrideWithValue(const DemoLocalisations()),
            ]
          : const [],
      child: const AagahiApp(),
    ),
  );
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
