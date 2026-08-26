import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/field_report.dart';
import '../providers/reporting_providers.dart';
import 'severity_screen.dart';

/// Screen F1 (screens_v2.html flow F) - the Report tab's root screen.
///
/// This is a tab root, not a pushed screen (matching RiskDashboardScreen
/// and AlertListScreen, the other two tab roots), so it has no back arrow.
class ObservationTypeScreen extends ConsumerWidget {
  const ObservationTypeScreen({super.key});

  static const _types = [
    (ObservationType.cropWilting, '🥀', 'observation.cropWilting'),
    (ObservationType.soilCracking, '🪨', 'observation.soilCracking'),
    (ObservationType.cropLoss, '📉', 'observation.cropLoss'),
    (ObservationType.allFine, '✅', 'observation.allFine'),
    (ObservationType.irrigated, '💧', 'observation.irrigated'),
    (ObservationType.rained, '🌧️', 'observation.rained'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final selected = ref.watch(fieldReportDraftProvider).observationType;

    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.edge),
            ),
            child: Text(
              l10n.translate('reporting.localOnlyBanner'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('reporting.whatDidYouSee'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            children: [
              for (final (type, icon, labelKey) in _types)
                _ObservationTile(
                  icon: icon,
                  label: l10n.translate(labelKey),
                  selected: selected == type,
                  onTap: () =>
                      ref.read(fieldReportDraftProvider.notifier).setObservationType(type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: selected == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SeverityScreen()),
                    ),
            child: Text(l10n.translate('action.next')),
          ),
        ],
      ),
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.seed.withValues(alpha: 0.15) : AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.seed : AppColors.edge,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
