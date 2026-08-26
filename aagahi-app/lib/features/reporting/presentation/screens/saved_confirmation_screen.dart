import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/field_report.dart';
import '../providers/reporting_providers.dart';

/// Screen F6 (screens_v2.html flow F) - saved-offline confirmation.
///
/// Deliberately does not say "sent automatically later" the way the
/// reference mockup does: there is no outbox in this phase, so that would
/// be a promise this build cannot keep (CLAUDE.md S1 - never render an
/// absence of a feature as if it already covers you). The saved-count chip
/// is real, read live from the database via [savedReportsCountProvider],
/// not the mockup's fixed "3 items".
class SavedConfirmationScreen extends ConsumerWidget {
  const SavedConfirmationScreen({required this.report, super.key});

  final FieldReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final count = ref.watch(savedReportsCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.seed, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('💾', style: TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.translate('reporting.savedOnPhone'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('reporting.savedExplanation'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: count.when(
                  data: (value) => Text(
                    l10n
                        .translate('reporting.savedCountChip')
                        .replaceFirst('{count}', '$value'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  loading: () => const SizedBox(
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(l10n.translate('action.done')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
