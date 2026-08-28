import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';

/// Screen G2 (screens_v2.html flow G) - conflict resolution.
///
/// Explicitly seeded (agreed 2026-08-27): there is no real multi-device
/// sync yet, so there is no real conflict to show. The two field-version
/// cards below use the reference's own illustrative numbers verbatim,
/// not independently invented ones - this screen demonstrates the UI a
/// real conflict will need, it does not pretend one exists today. Both
/// buttons just return to G1: neither has a real server write to make.
class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Text(
                l10n.translate('sync.conflictBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('sync.conflictTitle'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.translate('sync.conflictBody'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Chip(
                          label: l10n.translate('sync.onThisPhone'), on: true),
                      Text('21 Aug 08:02',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('3.5 acres · 🌾 Wheat',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Water: rain only',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Chip(
                          label: l10n.translate('sync.onTheServer'), on: false),
                      Text('20 Aug 17:41',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('4.0 acres · 🌾 Wheat',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Water: canal',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('sync.seededNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('action.keepMyPhoneVersion')),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('action.keepServerVersion')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: on ? AppColors.seed.withValues(alpha: 0.18) : AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? AppColors.seed : AppColors.edge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: on ? AppColors.seed : AppColors.ink2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
