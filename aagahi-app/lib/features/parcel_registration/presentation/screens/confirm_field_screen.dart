import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/crop_catalog.dart';
import '../../domain/entities/parcel.dart';
import '../providers/parcel_registration_providers.dart';

const _waterLabelKeys = {
  WaterSource.rainOnly: 'water.rainOnly',
  WaterSource.canal: 'water.canal',
  WaterSource.tubewell: 'water.tubewell',
  WaterSource.mixed: 'water.mixed',
};

const _soilLabelKeys = {
  SoilType.sandy: 'soil.sandy',
  SoilType.loam: 'soil.loam',
  SoilType.clay: 'soil.clay',
  SoilType.unknown: 'soil.unknown',
};

/// Screen B7 (screens_v2.html flow B) - review and save.
///
/// "Save this field" writes a real `Parcel` row to Drift. This is the
/// last screen of the whole A1-B7 chain: on success the entire onboarding
/// and registration stack is replaced with [AppShell], and
/// `currentParcelIdProvider` is pointed at the parcel that was just
/// created so Home shows it immediately, not the demo default.
class ConfirmFieldScreen extends StatefulWidget {
  const ConfirmFieldScreen({super.key});

  @override
  State<ConfirmFieldScreen> createState() => _ConfirmFieldScreenState();
}

class _ConfirmFieldScreenState extends State<ConfirmFieldScreen> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _save(WidgetRef ref, Parcel parcel) async {
    setState(() {
      _saving = true;
      _failed = false;
    });

    final result = await ref.read(parcelRepositoryProvider).save(parcel);

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _failed = true;
      }),
      (saved) {
        ref.read(currentParcelIdProvider.notifier).state = saved.id;
        ref.read(parcelDraftProvider.notifier).reset();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final draft = ref.watch(parcelDraftProvider);
        final crop = cropById(draft.cropId!);
        final sowingDate = draft.sowingDate!;

        final parcel = Parcel(
          id: const Uuid().v4(),
          areaAcres: draft.areaAcres!,
          cropId: draft.cropId!,
          sowingDate: sowingDate,
          waterSource: draft.waterSource!,
          soilType: draft.soilType!,
          createdAt: DateTime.now().toUtc(),
          latitude: draft.latitude,
          longitude: draft.longitude,
        );

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ListenPill(
                  label: l10n.translate('action.readItBack'),
                  isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                  onPressed: () => ref
                      .read(briefingPlaybackProvider.notifier)
                      .speakText(l10n.translate('registration.confirmTitle')),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.translate('registration.confirmTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      _ReviewRow(
                        label: l10n.translate('registration.fieldLabel'),
                        value: l10n.translate('parcels.myField'),
                      ),
                      _ReviewRow(
                        label: l10n.translate('registration.sizeLabel'),
                        value:
                            '${parcel.areaAcres.toStringAsFixed(1)} ${l10n.translate('registration.areaUnit')}',
                        showDivider: true,
                      ),
                      _ReviewRow(
                        label: l10n.translate('registration.cropLabel'),
                        value: '${crop.icon} ${l10n.translate(crop.nameKey)}',
                        showDivider: true,
                      ),
                      _ReviewRow(
                        label: l10n.translate('registration.stageLabel'),
                        value: l10n.translate(parcel.stageKey(DateTime.now())),
                        showDivider: true,
                      ),
                      _ReviewRow(
                        label: l10n.translate('registration.waterLabel'),
                        value: l10n
                            .translate(_waterLabelKeys[parcel.waterSource]!),
                        showDivider: true,
                      ),
                      _ReviewRow(
                        label: l10n.translate('registration.soilLabel'),
                        value: l10n.translate(_soilLabelKeys[parcel.soilType]!),
                        showDivider: true,
                      ),
                    ],
                  ),
                ),
                if (_failed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.translate('registration.saveFailed'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.severe),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : () => _save(ref, parcel),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onSeed),
                        )
                      : Text(l10n.translate('action.saveThisField')),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.translate('action.changeSomething')),
                ),
              ],
            ),
          ),
        );
      },
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
