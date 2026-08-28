import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../reporting/domain/entities/field_report.dart';
import '../../../reporting/presentation/providers/reporting_providers.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'conflict_resolution_screen.dart';

const _observationIcons = {
  ObservationType.cropWilting: '🥀',
  ObservationType.soilCracking: '🪨',
  ObservationType.cropLoss: '📉',
  ObservationType.allFine: '✅',
  ObservationType.irrigated: '💧',
  ObservationType.rained: '🌧️',
};

/// Screen G1 (screens_v2.html flow G) - sync status.
///
/// The reference shows a live upload ("Sending 3 of 5", per-item Sent/
/// Sending/conflict states) - none of that exists yet: there is no
/// outbox or upload path this phase. What is real is the count and list
/// of field reports actually saved locally (`FieldReportRepository`,
/// flow F) - shown honestly as permanently `LOCAL_ONLY`, not a fake
/// send-in-progress state.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final count = ref.watch(savedReportsCountProvider).valueOrNull ?? 0;
    final reports =
        ref.watch(allFieldReportsProvider).valueOrNull ?? const <FieldReport>[];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Expanded(
                  child: Text(l10n.translate('sync.title'),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  Text(
                    l10n
                        .translate('sync.localOnlySummary')
                        .replaceFirst('{count}', '$count'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('sync.allLocalNote'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.translate('sync.noReportsYet'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final report in reports)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.low,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _observationIcons[report.observationType] ?? '📋',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('d MMM').format(report.createdAt),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              l10n.translate('sync.savedOnPhone'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ConflictResolutionScreen()),
                ),
                child: Text(l10n.translate('sync.seeConflictDemo')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('sync.neverAutoDeleted'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
