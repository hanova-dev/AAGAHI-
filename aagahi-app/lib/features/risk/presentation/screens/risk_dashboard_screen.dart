import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../../parcel_registration/domain/entities/crop_catalog.dart';
import '../../../parcel_registration/domain/entities/parcel.dart';
import '../../../parcel_registration/presentation/providers/parcel_registration_providers.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';
import 'causal_explanation_screen.dart';
import 'not_scorable_view.dart';
import 'parcel_switcher_view.dart';
import 'stale_assessment_view.dart';

/// Screen C1 - the landing surface and the only screen most farmers will open.
///
/// Four states get first-class treatment rather than being lumped into a
/// generic error view:
///   * scored          - the normal case
///   * not scorable    - satellites gave us nothing; we say so ([NotScorableView], C3)
///   * offline / stale - we show the last reading and date it loudly ([StaleAssessmentView], C4)
///   * any other failure (server/auth/no-cache-offline) - generic [_FailureView]
///
/// The stale case is where most weather apps quietly cheat by showing an old
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
            error: (error, _) {
              final failure = error is Failure ? error : const ServerFailure();
              if (failure is NotScorableFailure) {
                return NotScorableView(parcelId: parcelId, failure: failure);
              }
              return _FailureView(
                failure: failure,
                onRetry: () => ref
                    .read(riskAssessmentProvider(parcelId).notifier)
                    .refresh(force: true),
              );
            },
            data: (assessment) {
              if (assessment.isStaleAsOf(DateTime.now().toUtc())) {
                return StaleAssessmentView(assessment: assessment);
              }
              return _ScoredView(assessment: assessment);
            },
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
            onPressed: () =>
                ref.read(briefingPlaybackProvider.notifier).toggle(assessment),
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

/// A [ConsumerWidget], not [StatelessWidget]: for a real registered parcel
/// (flow B), the name/crop/stage shown here come from the saved [Parcel]
/// row, not from [AppLocalisations.parcelName]/`.cropAndStage`, whose
/// hardcoded lookup only ever covered the four seeded demo parcels and
/// would otherwise silently mislabel a farmer's own field as "Chak 42/GB"
/// (CLAUDE.md S1 - a wrong label is a smaller lie than a wrong risk score,
/// but it is the same kind of lie).
class _ParcelHeader extends ConsumerWidget {
  const _ParcelHeader({required this.assessment, required this.l10n});

  final RiskAssessment assessment;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registered = ref.watch(registeredParcelProvider).valueOrNull;
    final isRegistered =
        registered != null && registered.id == assessment.parcelId;

    final nameText = isRegistered
        ? l10n.translate('parcels.myField')
        : l10n.parcelName(
            assessment.parcelId,
          );
    final cropAndStageText = isRegistered
        ? _realCropAndStage(registered, l10n)
        : l10n.cropAndStage(assessment.parcelId);

    return InkWell(
      // Tapping the current field's name is how C2 (the parcel switcher)
      // is reached - matching the reference, where C2 has no other
      // entrance point of its own.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ParcelSwitcherView()),
      ),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nameText,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 4),
                    const Icon(Icons.unfold_more,
                        size: 14, color: AppColors.ink3),
                  ],
                ),
                const SizedBox(height: 2),
                Text(cropAndStageText,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          Text(
            l10n.assessedOn(assessment.assessedOn),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _realCropAndStage(Parcel parcel, AppLocalisations l10n) {
  final crop = cropById(parcel.cropId);
  final stage = l10n.translate(parcel.stageKey(DateTime.now().toUtc()));
  return '${crop.icon} ${l10n.translate(crop.nameKey)} · $stage';
}

class _DriverList extends StatelessWidget {
  const _DriverList({required this.assessment, required this.l10n});

  final RiskAssessment assessment;
  final AppLocalisations l10n;

  @override
  Widget build(BuildContext context) {
    if (assessment.drivers.isEmpty) return const SizedBox.shrink();

    return InkWell(
      // D1 (CausalExplanationScreen) has no entrance point of its own -
      // matching how C2 is only reachable via C1's parcel header.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CausalExplanationScreen(assessment: assessment),
        ),
      ),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.whyIsItDrying,
                    style: Theme.of(context).textTheme.bodySmall),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.ink3),
              ],
            ),
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

// ---------------------------------------------------------------------------
// Failure states
// ---------------------------------------------------------------------------

/// The generic fallback for failures without a dedicated screen: server
/// errors, auth failures, and "offline with nothing cached at all" (SRS
/// UC-03 alt-flow 3a). NotScorableFailure never reaches this widget - see
/// [RiskDashboardScreen], which routes it to [NotScorableView] instead.
class _FailureView extends ConsumerWidget {
  const _FailureView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 40, color: AppColors.ink2),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate(failure.messageKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('${failure.messageKey}.detail'),
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
            onPressed: () => ref
                .read(briefingPlaybackProvider.notifier)
                .speakText(l10n.translate(failure.messageKey)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
