import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';

const _cannotDoKeys = [
  'settings.cannotDo.rain',
  'settings.cannotDo.cropFate',
  'settings.cannotDo.replaceDept',
  'settings.cannotDo.wrongBefore',
  'settings.cannotDo.silentWhenBlind',
];

/// Screen H6 (screens_v2.html flow H) - "what this app cannot do."
///
/// The reference calls this screen out specifically: "a permanent in-app
/// statement of what this system cannot do, including its own
/// false-alarm rate." The performance figures below are the reference's
/// own stated numbers, not independently re-measured by this build - see
/// the doc comment on the keys in in_memory_localisations.dart. They are
/// deliberately framed as recall/false-alarm-rate in plain language
/// ("caught 7 of 10", "3 of 10 were false alarms"), never as bare
/// accuracy - CLAUDE.md is explicit that bare accuracy is meaningless
/// when the positive class is rare, and this is the farmer-facing
/// translation of that same rule.
class WhatThisCannotDoScreen extends ConsumerWidget {
  const WhatThisCannotDoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

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
                  child: Text(
                    l10n.translate('settings.cannotDo'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: ListenPill(
                label: l10n.listen,
                isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                onPressed: () => ref
                    .read(briefingPlaybackProvider.notifier)
                    .speakText(l10n.translate('settings.cannotDo')),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final key in _cannotDoKeys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('settings.performanceTitle'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('settings.performanceCaught'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('settings.performanceFalseAlarm'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('settings.versionFooter'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
