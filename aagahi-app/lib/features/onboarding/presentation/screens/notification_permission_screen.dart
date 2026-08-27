import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'phone_number_screen.dart';

/// Screen A6 (screens_v2.html flow A) - notification permission.
///
/// Does not request the real OS notification permission: there is no push
/// pipeline built yet (outbox/sync remain out of scope), so there is
/// nothing to gate on it. Informational only, matching A5's reasoning.
class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const Spacer(),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.notifTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.notifBody'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.edge),
                ),
                child: Text(
                  l10n.translate('onboarding.notifBanner'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const PhoneNumberScreen()),
                  ),
                  child: Text(l10n.translate('action.turnOnWarnings')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
