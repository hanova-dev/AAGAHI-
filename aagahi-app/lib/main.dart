import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/risk/presentation/screens/risk_dashboard_screen.dart';

/// Composition root.
///
/// Deliberately wires no provider overrides yet: `riskRepositoryProvider`
/// and `localisationProvider` (in `risk_providers.dart`) still throw
/// `UnimplementedError` until the local database, network layer, and
/// localisation exist (CLAUDE.md kickoff Phase 1). A fake override here would
/// make the app appear to run while hiding exactly how much is unbuilt - a
/// missing dependency should fail loudly at the point of use, not quietly
/// return placeholder data.
void main() {
  runApp(const ProviderScope(child: AagahiApp()));
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
