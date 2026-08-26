import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../demo/demo_risk_repository.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../providers/risk_providers.dart';

/// Screen C2 (screens_v2.html flow C) - switch which field Home shows.
///
/// Backed by the same seeded parcels [DemoRiskRepository] serves
/// ([demoParcelSummaries]/[currentParcelIdProvider]) - picking a row here
/// really does change the Home tab's content, through the existing
/// `riskAssessmentProvider(parcelId)` family provider. A switcher that
/// always showed the same field regardless of selection would be exactly
/// the kind of dead interaction this build avoids elsewhere (see C3's
/// district-warning button).
class ParcelSwitcherView extends ConsumerWidget {
  const ParcelSwitcherView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final currentParcelId = ref.watch(currentParcelIdProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Text(
                  l10n.translate('parcels.yourFields'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final summary in demoParcelSummaries)
              _ParcelTile(
                summary: summary,
                selected: summary.parcelId == currentParcelId,
                l10n: l10n,
                onTap: () {
                  ref.read(currentParcelIdProvider.notifier).state = summary.parcelId;
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: AppSpacing.md),
            // Disabled, not wired: parcel registration (B1-B7 in the
            // reference) is not built yet - out of scope for this phase.
            OutlinedButton(
              onPressed: null,
              child: Text(l10n.translate('parcels.addAnother')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParcelTile extends ConsumerWidget {
  const _ParcelTile({
    required this.summary,
    required this.selected,
    required this.l10n,
    required this.onTap,
  });

  final DemoParcelSummary summary;
  final bool selected;
  final AppLocalisations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(riskAssessmentProvider(summary.parcelId)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.seed.withValues(alpha: 0.17) : AppColors.glass,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.seed.withValues(alpha: 0.5) : AppColors.edge,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(summary.cropAndStage, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (assessment != null)
                BandChip(band: assessment.band, label: l10n.bandLabel(assessment.band)),
            ],
          ),
        ),
      ),
    );
  }
}
