import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../../risk/domain/entities/risk_assessment.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../../risk/presentation/screens/causal_explanation_screen.dart';
import '../providers/alerts_providers.dart';

/// Screen E2 (screens_v2.html flow E) - alert detail with the audio player.
///
/// The player is shipped with the briefing file deliberately absent
/// (agreed 2026-08-26): no synthesized audio, ever, in front of a board -
/// bad placeholder narration misrepresents a feature that genuinely has
/// not been built. Tapping play surfaces "briefing not downloaded", which
/// is an honest state this app already models
/// (`RiskRepository.ensureBriefingCached` returning `NetworkFailure`), not
/// a new fake one invented for this screen. Once a real clip exists at
/// `assets/audio/alert_briefing_demo.m4a` (declared in pubspec.yaml but not
/// bundled), this becomes a real player with no code change beyond
/// swapping the "not downloaded" branch for actual playback.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({required this.alertId, super.key});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final alerts = ref.watch(alertsProvider);
    final alert = alerts.firstWhere((a) => a.id == alertId);
    final assessment =
        ref.watch(riskAssessmentProvider(alert.parcelId)).valueOrNull;
    final canExplainWhy = assessment != null && assessment.drivers.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  l10n.translate('nav.warnings'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            BandChip(
              band: alert.band,
              label:
                  '${l10n.bandLabel(alert.band)} · ${DateFormat('d MMM HH:mm').format(alert.issuedAt).toUpperCase()}',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              alert.band == RiskBand.warning || alert.band == RiskBand.severe
                  ? l10n.translate('alerts.detail.dangerHeadline')
                  : l10n.translate(alert.headlineKey),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            if (alert.briefingDurationSeconds != null) ...[
              _AudioPlayerCard(
                  l10n: l10n, durationSeconds: alert.briefingDurationSeconds!),
              const SizedBox(height: AppSpacing.sm),
            ],
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('alerts.detail.doThisWeek'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate(alert.adviceKey),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (alert.acknowledged)
              OutlinedButton(
                onPressed: null,
                child: Text(l10n.translate('action.acknowledged')),
              )
            else
              FilledButton(
                onPressed: () =>
                    ref.read(alertsProvider.notifier).acknowledge(alert.id),
                child: Text(l10n.translate('action.iHaveHeardThis')),
              ),
            const SizedBox(height: AppSpacing.sm),
            // Disabled only when the assessment hasn't loaded yet or this
            // parcel genuinely has no drivers to explain (e.g. the
            // low-risk maize/mango scenarios) - the same condition
            // _DriverList uses to hide itself entirely on C1. Never
            // disabled just because the feature doesn't exist: D1 does.
            OutlinedButton(
              onPressed: canExplainWhy
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CausalExplanationScreen(assessment: assessment),
                        ),
                      )
                  : null,
              child: Text(l10n.translate('action.whyIsItDrying')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  const _AudioPlayerCard({required this.l10n, required this.durationSeconds});

  final AppLocalisations l10n;
  final int durationSeconds;

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  bool _triedToPlay = false;

  @override
  Widget build(BuildContext context) {
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;
    final durationLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return GlassCard(
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _triedToPlay = true),
            customBorder: const CircleBorder(),
            child: Container(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              decoration: const BoxDecoration(
                  color: AppColors.seed, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: AppColors.onSeed),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.l10n.translate('audio.urduVoiceMessage'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0,
                    minHeight: 7,
                    backgroundColor: AppColors.edge,
                    valueColor: AlwaysStoppedAnimation(AppColors.seed),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _triedToPlay
                      ? widget.l10n.translate('audio.briefingNotDownloaded')
                      : '0:00 / $durationLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
