import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/field_report.dart';
import '../providers/reporting_providers.dart';
import 'saved_confirmation_screen.dart';

/// Screen F5 (screens_v2.html flow F) - review before saving.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _saving = false;
  bool _failed = false;

  static const _observationLabels = {
    ObservationType.cropWilting: ('🥀', 'observation.cropWilting'),
    ObservationType.soilCracking: ('🪨', 'observation.soilCracking'),
    ObservationType.cropLoss: ('📉', 'observation.cropLoss'),
    ObservationType.allFine: ('✅', 'observation.allFine'),
    ObservationType.irrigated: ('💧', 'observation.irrigated'),
    ObservationType.rained: ('🌧️', 'observation.rained'),
  };

  Future<void> _save(String parcelId, ObservationType type, int severity,
      String? photoPath) async {
    setState(() {
      _saving = true;
      _failed = false;
    });

    final report = FieldReport(
      id: const Uuid().v4(),
      parcelId: parcelId,
      observationType: type,
      severity: severity,
      createdAt: DateTime.now().toUtc(),
      syncState: SyncState.localOnly,
      photoPath: photoPath,
    );

    final result = await ref.read(fieldReportRepositoryProvider).save(report);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _failed = true;
      }),
      (saved) {
        ref.read(fieldReportDraftProvider.notifier).reset();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
              builder: (_) => SavedConfirmationScreen(report: saved)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localisationProvider);
    final draft = ref.watch(fieldReportDraftProvider);
    final parcelId = ref.watch(currentParcelIdProvider);
    final type = draft.observationType!;
    final severity = draft.severity!;
    final (icon, labelKey) = _observationLabels[type]!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
              ],
            ),
            ListenPill(
              label: l10n.translate('action.readItBack'),
              isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
              onPressed: () =>
                  ref.read(briefingPlaybackProvider.notifier).speakText(
                        '${l10n.translate(labelKey)}. $severity/5.',
                      ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('reporting.reviewTitle'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                children: [
                  _ReviewRow(
                    label: l10n.translate('reporting.fieldWhat'),
                    value: '$icon ${l10n.translate(labelKey)}',
                  ),
                  _ReviewRow(
                    label: l10n.translate('reporting.fieldHowBad'),
                    value: '$severity/5',
                    showDivider: true,
                  ),
                  _ReviewRow(
                    label: l10n.translate('reporting.fieldPhoto'),
                    value: l10n.translate(
                      draft.photoPath == null
                          ? 'reporting.noPhoto'
                          : 'reporting.onePhoto',
                    ),
                    showDivider: true,
                  ),
                ],
              ),
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
                l10n.translate('reporting.localOnlyBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('reporting.saveFailed'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.severe),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () => _save(parcelId, type, severity, draft.photoPath),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onSeed),
                    )
                  : Text(l10n.translate('action.saveReport')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(
      {required this.label, required this.value, this.showDivider = false});

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.edge)))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
