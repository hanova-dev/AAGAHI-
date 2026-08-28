import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'microphone_permission_screen.dart';

/// Screen A4 (screens_v2.html flow A) - location permission.
///
/// "Allow location" triggers the real OS permission dialog here (via
/// geolocator) so it appears once, during onboarding, rather than as a
/// surprise later. The actual coordinate read happens in B1
/// ([FieldLocationScreen]), which handles a denial or a disabled location
/// service on its own - this screen never blocks on the outcome, matching
/// the reference's own "refuse and still use the app" framing.
class LocationPermissionScreen extends ConsumerWidget {
  const LocationPermissionScreen({super.key});

  Future<void> _requestAndAdvance(BuildContext context) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {
      // Falls through to B1's own honest "location not available" path.
    }
    if (!context.mounted) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => const MicrophonePermissionScreen()),
      ),
    );
  }

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
                    const Text('📍', style: TextStyle(fontSize: 34)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.locationTitle'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('onboarding.locationBody'),
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
                  l10n.translate('onboarding.locationRefusalBanner'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _requestAndAdvance(context),
                  child: Text(l10n.translate('action.allowLocation')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const MicrophonePermissionScreen()),
                  ),
                  child: Text(l10n.translate('action.notNow')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
