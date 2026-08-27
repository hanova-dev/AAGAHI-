import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'location_permission_screen.dart';

/// Screen A3 (screens_v2.html flow A) - "what this does."
///
/// The reference frames this as page 1 of a 3-page carousel, but only
/// supplies copy for that one page - pages 2 and 3 do not exist anywhere
/// in screens_v2.html. Rather than invent two pages of unreviewed product
/// copy, this is the one page that has real reference content, shown once;
/// the 3-dot row is kept as the reference's own visual (first dot lit) but
/// carries no second or third page behind it.
class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Center(
                child: ListenPill(
                  label: l10n.listen,
                  isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                  onPressed: () => ref
                      .read(briefingPlaybackProvider.notifier)
                      .speakText(l10n.translate('onboarding.introTitle')),
                ),
              ),
              const Spacer(),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('onboarding.introTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.introBody'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.seed,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...List.generate(
                    2,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.bark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const LocationPermissionScreen()),
                  ),
                  child: Text(l10n.translate('action.next')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
