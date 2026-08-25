import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../providers/risk_providers.dart';

/// Screen C3 (screens_v2.html flow C) - the satellite gave us nothing for
/// this parcel, so we say so instead of guessing.
///
/// This is not an error view with a retry button: retrying does not fix
/// "the satellite has not sent usable data," and a retry affordance here
/// would falsely imply the user did something wrong. There is structurally
/// no risk percentage or [BandChip] anywhere in this widget - see
/// CLAUDE.md S1 and the widget test guarding exactly that invariant.
class NotScorableView extends ConsumerWidget {
  const NotScorableView({required this.parcelId, required this.failure, super.key});

  final String parcelId;
  final NotScorableFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(l10n.parcelName(parcelId), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Text('🛰️', style: TextStyle(fontSize: 38)),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.translate(failure.messageKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate(failure.reasonKey),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.edge),
                ),
                child: Text(
                  // The product's ethical position, stated to the user.
                  l10n.notGuessingExplanation,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
        // Disabled, not wired: there is no district-aggregate feature built
        // yet (out of scope - officer console). Rendered for visual parity
        // with the reference design without pretending it does something.
        OutlinedButton(
          onPressed: null,
          child: Text(l10n.translate('action.seeDistrictWarning')),
        ),
      ],
    );
  }
}
