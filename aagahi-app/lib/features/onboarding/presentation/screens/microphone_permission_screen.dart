import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'notification_permission_screen.dart';

/// Screen A5 (screens_v2.html flow A) - microphone permission.
///
/// Neither button requests the OS microphone permission: voice input is
/// manual-entry only this phase (agreed 2026-08-27), so there is nothing
/// yet that would use it. Asking for a permission with no feature behind
/// it would be its own small dishonesty - both choices simply continue.
class MicrophonePermissionScreen extends ConsumerWidget {
  const MicrophonePermissionScreen({super.key});

  void _advance(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => const NotificationPermissionScreen()),
      );

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
                    const Text('🎙️', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.micTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.micBody'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _advance(context),
                  child: Text(l10n.translate('action.allowMicrophone')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _advance(context),
                  child: Text(l10n.translate('action.typeInstead')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
