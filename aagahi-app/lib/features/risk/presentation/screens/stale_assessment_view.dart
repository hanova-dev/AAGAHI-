import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';

/// Screen C4 (screens_v2.html flow C) - the last assessment we have is
/// older than [RiskAssessment.isStaleAsOf]'s threshold. We show it, dated,
/// loudly, twice (the top banner and the ring's own caption) - never as if
/// it were current. This is the screen most weather apps skip; showing an
/// old number without dating it is exactly the failure mode CLAUDE.md S1
/// exists to rule out.
class StaleAssessmentView extends ConsumerWidget {
  const StaleAssessmentView({required this.assessment, super.key});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final now = DateTime.now().toUtc();
    final ageDays = assessment.ageAsOf(now).inDays;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _Banner(
          color: AppColors.ink2,
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '${l10n.translate('offline.noInternetTitle')} ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                TextSpan(text: l10n.translate('offline.noInternetBody')),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.parcelName(assessment.parcelId), style: Theme.of(context).textTheme.bodySmall),
            _AgeChip(text: '$ageDays ${l10n.translate('common.daysOld')}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: 0.9,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                RiskRing(
                  probability: assessment.probability,
                  band: assessment.band,
                  trace: assessment.trace,
                  caption:
                      '${l10n.translate('common.asOf')} ${l10n.assessedOn(assessment.assessedOn)}',
                  semanticsLabel: l10n.ringSemantics(assessment),
                  size: 200,
                ),
                const SizedBox(height: AppSpacing.sm),
                BandChip(band: assessment.band, label: l10n.bandLabel(assessment.band)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Banner(
          color: AppColors.warning,
          child: Text(
            l10n.translate('offline.staleWarningBanner'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ListenPill(
            label: '${l10n.listen} (${l10n.translate('common.saved')})',
            isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
            onPressed: () =>
                ref.read(briefingPlaybackProvider.notifier).toggle(assessment),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () => ref
              .read(riskAssessmentProvider(assessment.parcelId).notifier)
              .refresh(force: true),
          child: Text(l10n.translate('action.tryToConnect')),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: child,
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.edge),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
