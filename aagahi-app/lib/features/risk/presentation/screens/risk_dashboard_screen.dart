import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';

/// Screen C1 - the landing surface and the only screen most farmers will open.
///
/// Three states get first-class treatment rather than being lumped into a
/// generic error view:
///   * scored          - the normal case
///   * not scorable    - satellites gave us nothing; we say so (C3)
///   * offline / stale - we show the last reading and date it loudly (C4)
///
/// The third one is where most weather apps quietly cheat by showing an old
/// number as if it were current. Dating it is the difference between a farmer
/// making an informed call and being misled.
class RiskDashboardScreen extends ConsumerWidget {
  const RiskDashboardScreen({required this.parcelId, super.key});

  final String parcelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riskAssessmentProvider(parcelId));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.seed,
          backgroundColor: AppColors.canopy,
          onRefresh: () => ref
              .read(riskAssessmentProvider(parcelId).notifier)
              .refresh(force: true),
          child: state.when(
            loading: () => const _LoadingView(),
            error: (error, _) => _FailureView(
              failure: error is Failure ? error : const ServerFailure(),
              onRetry: () => ref
                  .read(riskAssessmentProvider(parcelId).notifier)
                  .refresh(force: true),
            ),
            data: (assessment) => _ScoredView(assessment: assessment),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scored
// ---------------------------------------------------------------------------

class _ScoredView extends ConsumerWidget {
  const _ScoredView({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final now = DateTime.now().toUtc();
    final isStale = assessment.isStaleAsOf(now);

    return ListView(
      // AlwaysScrollable so pull-to-refresh works even when content is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        if (isStale)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StaleBanner(
              ageDays: assessment.ageAsOf(now).inDays,
              l10n: l10n,
            ),
          ),

        _ParcelHeader(assessment: assessment, l10n: l10n),
        const SizedBox(height: AppSpacing.md),

        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              RiskRing(
                probability: assessment.probability,
                band: assessment.band,
                trace: assessment.trace,
                caption: l10n.horizonCaption(assessment.horizonDays),
                semanticsLabel: l10n.ringSemantics(assessment),
                size: 210,
              ),
              const SizedBox(height: AppSpacing.sm),
              BandChip(
                band: assessment.band,
                label: l10n.bandLabel(assessment.band),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.rateSummary(assessment),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Center(
          child: ListenPill(
            label: l10n.listen,
            isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
            duration: ref.watch(briefingPlaybackProvider).duration,
            onPressed: () => ref
                .read(briefingPlaybackProvider.notifier)
                .toggle(assessment),
          ),
        ),

        if (assessment.advisoryTitleKey != null) ...[
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whatToDo,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.translate(assessment.advisoryTitleKey!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),
        _DriverList(assessment: assessment, l10n: l10n),

        // Confidence is stated on the primary surface, not buried in a detail
        // screen. A farmer deciding whether to spend money on an irrigation
        // turn needs to know how sure we are at the moment of the decision.
        const SizedBox(height: AppSpacing.md),
        _ConfidenceRow(assessment: assessment, l10n: l10n),
      ],
    );
  }
}

class _ParcelHeader extends StatelessWidget {
  const _ParcelHeader({required this.assessment, required this.l10n});

  final RiskAssessment assessment;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.parcelName(assessment.parcelId),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cropAndStage(assessment.parcelId),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Text(
          l10n.assessedOn(assessment.assessedOn),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DriverList extends StatelessWidget {
  const _DriverList({required this.assessment, required this.l10n});

  final RiskAssessment assessment;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    if (assessment.drivers.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.whyIsItDrying, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final driver in assessment.drivers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Narrative key, never the raw SHAP value (FR-EXPL-007).
                    l10n.translate(driver.narrativeKey),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: driver.relativeWeight,
                      minHeight: 7,
                      backgroundColor: AppColors.edge,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.forBand(assessment.band),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({required this.assessment, required this.l10n});

  final RiskAssessment assessment;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.howSureAreWe,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.confidenceLabel(assessment.confidence),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (assessment.usedDegradedInputs) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.degradedInputsNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.ink3),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.ageDays, required this.l10n});

  final int ageDays;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.36)),
      ),
      child: Text(
        l10n.staleWarning(ageDays),
        style: const TextStyle(color: Color(0xFFF3CBA1), fontSize: 12, height: 1.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Failure states
// ---------------------------------------------------------------------------

class _FailureView extends ConsumerWidget {
  const _FailureView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    // NotScorable is not an error. The system worked and is declining to
    // guess, so it gets its own explanation rather than a retry prompt that
    // implies the user did something wrong.
    final isNotScorable = failure is NotScorableFailure;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                isNotScorable ? Icons.satellite_alt : Icons.cloud_off,
                size: 40,
                color: AppColors.ink2,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate(failure.messageKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                switch (failure) {
                  NotScorableFailure(:final reasonKey) => l10n.translate(reasonKey),
                  _ => l10n.translate('${failure.messageKey}.detail'),
                },
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isNotScorable) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.edge),
                  ),
                  child: Text(
                    // The product's ethical position, stated to the user.
                    l10n.notGuessingExplanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: ListenPill(
            label: l10n.listen,
            onPressed: () => ref
                .read(briefingPlaybackProvider.notifier)
                .speakText(l10n.translate(failure.messageKey)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!isNotScorable)
          FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.seed),
      );
}
