import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/parcel.dart';
import '../providers/parcel_registration_providers.dart';
import 'confirm_field_screen.dart';

const _soilMeta = {
  SoilType.sandy: ('🏜️', 'soil.sandy', 'soil.sandyDesc'),
  SoilType.loam: ('🟤', 'soil.loam', 'soil.loamDesc'),
  SoilType.clay: ('🧱', 'soil.clay', 'soil.clayDesc'),
  SoilType.unknown: ('❔', 'soil.unknown', 'soil.unknownDesc'),
};

/// Screen B6 (screens_v2.html flow B) - soil type.
class SoilTypeScreen extends StatefulWidget {
  const SoilTypeScreen({super.key});

  @override
  State<SoilTypeScreen> createState() => _SoilTypeScreenState();
}

class _SoilTypeScreenState extends State<SoilTypeScreen> {
  SoilType? _selected;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListenPill(
                    label: l10n.listen,
                    isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                    onPressed: () => ref
                        .read(briefingPlaybackProvider.notifier)
                        .speakText(l10n.translate('registration.soilTitle')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.translate('registration.soilTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('registration.soilBody'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final soil in SoilType.values) ...[
                    _SoilTile(
                      soil: soil,
                      l10n: l10n,
                      selected: soil == _selected,
                      onTap: () => setState(() => _selected = soil),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selected == null
                          ? null
                          : () {
                              ref
                                  .read(parcelDraftProvider.notifier)
                                  .setSoilType(_selected!);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ConfirmFieldScreen(),
                                ),
                              );
                            },
                      child: Text(l10n.translate('action.next')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SoilTile extends StatelessWidget {
  const _SoilTile({
    required this.soil,
    required this.l10n,
    required this.selected,
    required this.onTap,
  });

  final SoilType soil;
  final AppLocalisations l10n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, labelKey, descKey) = _soilMeta[soil]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.seed.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: selected ? AppColors.seed : AppColors.edge),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.translate(labelKey),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(l10n.translate(descKey),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
