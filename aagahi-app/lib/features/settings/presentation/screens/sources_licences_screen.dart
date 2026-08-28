import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';

const _sources = [
  ('settings.source.smap', 'settings.source.smapDesc'),
  ('settings.source.era5', 'settings.source.era5Desc'),
  ('settings.source.tropomi', 'settings.source.tropomiDesc'),
  ('settings.source.chirps', 'settings.source.chirpsDesc'),
  ('settings.source.modis', 'settings.source.modisDesc'),
];

/// Screen H5 (screens_v2.html flow H) - static content: the real data
/// sources and open-source licences this project's design documents
/// (CLAUDE.md) already name for the signal pipeline, not a placeholder
/// list invented for this screen.
class SourcesLicencesScreen extends ConsumerWidget {
  const SourcesLicencesScreen({super.key});

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
                    l10n.translate('settings.sources'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (nameKey, descKey) in _sources)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate(nameKey),
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(l10n.translate(descKey),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Text(
                l10n.translate('settings.openSourceCredits'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
