import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';
import 'confidence_screen.dart';

/// Screen D3 (screens_v2.html flow D) - "what to do," reached from D2
/// ([TraceDetailScreen]) when the assessment carries advisory content.
///
/// Rain-fed parcels ([RiskAssessment.isRainFed]) never see irrigation
/// advice here: the seeded wheat scenario carries conservation advice
/// (weeding/mulching) instead, plus an explicit "why not irrigation?" card,
/// because recommending water a farmer does not have is not a caveat away
/// from being useless - it is advice the farmer cannot act on.
class WhatToDoScreen extends ConsumerWidget {
  const WhatToDoScreen({required this.assessment, super.key});

  final RiskAssessment assessment;

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
                Text(l10n.whatToDo,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (assessment.advisoryTitleKey != null)
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BandChip(
                      band: assessment.band,
                      label: l10n.translate('alerts.detail.doThisWeek'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.translate(assessment.advisoryTitleKey!),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (assessment.advisoryBodyKey != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.translate(assessment.advisoryBodyKey!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            if (assessment.isRainFed) ...[
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('advisory.whyNotIrrigation'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.translate('advisory.whyNotIrrigation.body'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ListenPill(
                label: l10n.listen,
                isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                onPressed: () => ref
                    .read(briefingPlaybackProvider.notifier)
                    .toggle(assessment),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DoneButton(l10n: l10n),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConfidenceScreen(assessment: assessment),
                  ),
                ),
                child: Text(l10n.howSureAreWe),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends StatefulWidget {
  const _DoneButton({required this.l10n});

  final AppLocalisations l10n;

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    // Local widget state only, matching AlertDetailScreen's
    // heard/acknowledged pattern - there is no persistence layer for
    // "advisory completed" (out of scope for this item), so this does not
    // pretend to survive navigating away and back.
    return _done
        ? OutlinedButton(
            onPressed: null,
            child: Text(widget.l10n.translate('action.done')),
          )
        : FilledButton(
            onPressed: () => setState(() => _done = true),
            child: Text(widget.l10n.translate('action.iHaveDoneThis')),
          );
  }
}
