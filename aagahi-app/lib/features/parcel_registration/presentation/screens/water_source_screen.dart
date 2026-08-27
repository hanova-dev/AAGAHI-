import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/parcel.dart';
import '../providers/parcel_registration_providers.dart';
import 'soil_type_screen.dart';

const _waterMeta = {
  WaterSource.rainOnly: ('🌧️', 'water.rainOnly'),
  WaterSource.canal: ('🚿', 'water.canal'),
  WaterSource.tubewell: ('⚙️', 'water.tubewell'),
  WaterSource.mixed: ('🔀', 'water.mixed'),
};

/// Screen B5 (screens_v2.html flow B) - water source.
///
/// Selecting "Rain only" sets `Parcel.isRainFed` (via [WaterSource.rainOnly])
/// - the same flag D3 checks before ever suggesting irrigation.
class WaterSourceScreen extends StatefulWidget {
  const WaterSourceScreen({super.key});

  @override
  State<WaterSourceScreen> createState() => _WaterSourceScreenState();
}

class _WaterSourceScreenState extends State<WaterSourceScreen> {
  WaterSource? _selected;

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
                        .speakText(l10n.translate('registration.waterTitle')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.translate('registration.waterTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('registration.waterBody'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.4,
                    children: [
                      for (final source in WaterSource.values)
                        _WaterTile(
                          source: source,
                          l10n: l10n,
                          selected: source == _selected,
                          onTap: () => setState(() => _selected = source),
                        ),
                    ],
                  ),
                  if (_selected == WaterSource.rainOnly) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.translate('registration.rainFedBanner'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
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
                                  .setWaterSource(_selected!);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SoilTypeScreen(),
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

class _WaterTile extends StatelessWidget {
  const _WaterTile({
    required this.source,
    required this.l10n,
    required this.selected,
    required this.onTap,
  });

  final WaterSource source;
  final AppLocalisations l10n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, labelKey) = _waterMeta[source]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.seed.withValues(alpha: 0.15)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.seed : AppColors.edge,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(l10n.translate(labelKey),
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
