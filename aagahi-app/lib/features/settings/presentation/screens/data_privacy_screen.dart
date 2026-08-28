import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../onboarding/presentation/screens/splash_screen.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../providers/settings_providers.dart';

/// Screen H4 (screens_v2.html flow H) - data and privacy.
///
/// "Download my data" and "Read the privacy notice" are honestly inert -
/// neither is asked for as a real feature this item, and a fake data
/// export or an unreviewed "privacy notice" would be worse than an
/// admitted gap. "Delete my account" is real: it wipes every local table
/// (see `AppDatabase.wipeAllData`) after an explicit confirmation, then
/// returns to onboarding - there is no server copy to also delete, since
/// no backend exists yet, so the local wipe is the entire, real effect.
class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  String? _inertTapped;

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(localisationProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.canopy,
        title: Text(
          l10n.translate('settings.deleteConfirmTitle'),
          style: const TextStyle(color: AppColors.ink),
        ),
        content: Text(
          l10n.translate('settings.deleteConfirmBody'),
          style: const TextStyle(color: AppColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.translate('action.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.translate('action.deleteForever'),
              style: const TextStyle(color: AppColors.severe),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(settingsRepositoryProvider).deleteAllData();

    if (!context.mounted) return;
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
        (route) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    l10n.translate('settings.dataAndPrivacy'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('settings.whatWeKeep'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('settings.whatWeKeepBody'),
                    style: Theme.of(context).textTheme.bodyMedium,
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
                    l10n.translate('settings.whoCanSeeLocation'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('settings.whoCanSeeLocationBody'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _InertRow(
              title: l10n.translate('settings.downloadMyData'),
              tapped: _inertTapped == 'download',
              notice: l10n.translate('settings.notAvailableYet'),
              onTap: () => setState(() => _inertTapped = 'download'),
            ),
            _InertRow(
              title: l10n.translate('settings.readPrivacyNotice'),
              subtitle: l10n.translate('settings.readPrivacyNoticeSubtitle'),
              tapped: _inertTapped == 'privacy',
              notice: l10n.translate('settings.notAvailableYet'),
              onTap: () => setState(() => _inertTapped = 'privacy'),
            ),
            InkWell(
              onTap: () => _confirmAndDelete(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('settings.deleteAccount'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.severe),
                          ),
                          Text(
                            l10n.translate('settings.deleteAccountSubtitle'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.ink3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('settings.neverSellData'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InertRow extends StatelessWidget {
  const _InertRow({
    required this.title,
    required this.tapped,
    required this.notice,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool tapped;
  final String notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink3),
              ],
            ),
            if (tapped)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child:
                    Text(notice, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
