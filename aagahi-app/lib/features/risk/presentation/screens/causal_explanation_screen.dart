import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';
import 'trace_detail_screen.dart';

/// Screen D1 (screens_v2.html flow D) - "what is causing this," reached by
/// tapping C1's causal panel ([RiskDashboardScreen]'s `_DriverList`).
///
/// The farmer never sees a SHAP number here either: same rule as the panel
/// it was opened from (FR-EXPL-007), just with room for a third driver and
/// the closing banner the compact panel has no space for.
class CausalExplanationScreen extends ConsumerWidget {
  const CausalExplanationScreen({required this.assessment, super.key});

  final RiskAssessment assessment;

  static const _rankKeys = [
    'driverRank.biggest',
    'driverRank.second',
    'driverRank.third',
  ];

  // Ranked by position, not by risk band - the reference colours the three
  // cards warn/watch/low regardless of the assessment's own band, since
  // these bars compare drivers against each other, not against the ladder.
  static const _rankColors = [
    AppColors.warning,
    AppColors.watch,
    AppColors.low
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Text(
                  l10n.translate('action.whyIsItDrying'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Center(
              child: ListenPill(
                label: l10n.listen,
                isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                onPressed: () => ref
                    .read(briefingPlaybackProvider.notifier)
                    .toggle(assessment),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < assessment.drivers.length; i++) ...[
              _DriverCard(
                driver: assessment.drivers[i],
                rankLabel: l10n.translate(_rankKeys[i]),
                barColor: _rankColors[i],
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            GlassCard(
              child: Text(
                l10n.translate('causal.closingBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (assessment.trace.length >= 2) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TraceDetailScreen(assessment: assessment),
                    ),
                  ),
                  child: Text(l10n.translate('action.view14DayTrend')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.rankLabel,
    required this.barColor,
    required this.l10n,
  });

  final RiskDriver driver;
  final String rankLabel;
  final Color barColor;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    final footnoteKey = '${driver.narrativeKey}.footnote';
    final footnote = l10n.translate(footnoteKey);
    // translate() falls back to the raw key for anything untranslated
    // (see InMemoryLocalisations.translate) - most drivers have no
    // footnote, so this is how that "no footnote" case is detected here.
    final hasFootnote = footnote != footnoteKey;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rankLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            l10n.translate(driver.narrativeKey),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: driver.relativeWeight,
              minHeight: 7,
              backgroundColor: AppColors.edge,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (hasFootnote) ...[
            const SizedBox(height: 6),
            Text(footnote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
