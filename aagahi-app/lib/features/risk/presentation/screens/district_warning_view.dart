import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/risk_ring.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';

/// Target of C3's "See district warning instead" button - a real, minimal
/// screen backed by seeded data (district name, a band, a date), not a
/// disabled button. Agreed 2026-08-26: a button that does nothing invites
/// "so what does that do?" from a board member with no good answer.
///
/// District-level aggregation (FR-CONS-001, the extension officer console)
/// is out of scope for this phase - there is no real aggregate risk
/// computation behind this. The single seeded reading below is honestly
/// scoped as a stand-in, not presented as live district monitoring.
class DistrictWarningView extends ConsumerWidget {
  const DistrictWarningView({super.key});

  static const _districtName = 'Faisalabad-Jhang';
  static const _band = RiskBand.watch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final asOf = DateTime.now().toUtc().subtract(const Duration(hours: 6));

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
                  l10n.translate('district.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text(_districtName, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.translate('common.asOf')} ${l10n.assessedOn(asOf)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BandChip(band: _band, label: l10n.bandLabel(_band)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('district.explanation'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
