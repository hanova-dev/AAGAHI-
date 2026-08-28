import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/alerts/presentation/screens/alert_list_screen.dart';
import 'features/reporting/presentation/screens/observation_type_screen.dart';
import 'features/risk/presentation/providers/risk_providers.dart';
import 'features/risk/presentation/screens/risk_dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_home_screen.dart';

/// Bottom-nav shell (screens_v2.html's C1 navbar: Home / Warnings / Report /
/// Settings). All four tabs are built.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _builtTabCount = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localisationProvider);
    final parcelId = ref.watch(currentParcelIdProvider);

    final pages = [
      RiskDashboardScreen(parcelId: parcelId),
      const AlertListScreen(),
      const ObservationTypeScreen(),
      const SettingsHomeScreen(),
    ];

    return Scaffold(
      body: SafeArea(
          bottom: false, child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: AppColors.soil2,
        indicatorColor: AppColors.seed.withValues(alpha: 0.2),
        onDestinationSelected: (index) {
          if (index >= _builtTabCount) return;
          setState(() => _index = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.seed),
            label: l10n.translate('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon:
                const Icon(Icons.notifications, color: AppColors.seed),
            label: l10n.translate('nav.warnings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.mic_none_outlined),
            selectedIcon: const Icon(Icons.mic, color: AppColors.seed),
            label: l10n.translate('nav.report'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.seed),
            label: l10n.translate('nav.settings'),
          ),
        ],
      ),
    );
  }
}
