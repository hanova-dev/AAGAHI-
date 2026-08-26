import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';

/// Screen D4 (screens_v2.html flow D) - "how sure are we," reached from D3
/// ([WhatToDoScreen]). Closes flow D's loop: C1 -> D1 -> D2 -> D3 -> D4,
/// each screen's back arrow popping one level back through that same stack.
///
/// The confidence bar's fill is a coarse three-step visual (one step per
/// [ConfidenceLevel]), never a number - [RiskAssessment.confidence]'s own
/// doc comment is explicit that a farmer cannot act on "63% confident," and
/// that rule does not stop applying just because this screen has more room
/// than C1's summary row.
class ConfidenceScreen extends ConsumerWidget {
  const ConfidenceScreen({required this.assessment, super.key});

  final RiskAssessment assessment;

  static const _barFraction = {
    ConfidenceLevel.moderate: 0.45,
    ConfidenceLevel.good: 0.7,
    ConfidenceLevel.high: 0.92,
  };

  static const _barColor = {
    ConfidenceLevel.moderate: AppColors.watch,
    ConfidenceLevel.good: AppColors.low,
    ConfidenceLevel.high: AppColors.low,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final level = assessment.confidence;
    final explanation = assessment.usedDegradedInputs
        ? l10n.translate('confidence.explanationDegraded')
        : l10n.translate('confidence.explanationComplete');

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
                Text(l10n.howSureAreWe, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('confidence.title'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.confidenceLabel(level),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _barFraction[level],
                      minHeight: 7,
                      backgroundColor: AppColors.edge,
                      valueColor: AlwaysStoppedAnimation(_barColor[level]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('confidence.cannotDoTitle'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final key in [
                    'confidence.cannotDo.rain',
                    'confidence.cannotDo.cropFailure',
                    'confidence.cannotDo.wrongBefore',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '· ${l10n.translate(key)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Text(
                l10n.translate('confidence.districtAdvisoryBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
