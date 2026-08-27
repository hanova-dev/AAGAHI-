import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/parcel.dart';
import '../providers/parcel_registration_providers.dart';
import 'water_source_screen.dart';

/// Screen B4 (screens_v2.html flow B) - sowing date.
class SowingDateScreen extends StatefulWidget {
  const SowingDateScreen({super.key});

  @override
  State<SowingDateScreen> createState() => _SowingDateScreenState();
}

class _SowingDateScreenState extends State<SowingDateScreen> {
  DateTime? _sowingDate;
  int? _selectedOption;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _sowingDate = picked;
        _selectedOption = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final now = DateTime.now();
        final days =
            _sowingDate == null ? null : now.difference(_sowingDate!).inDays;

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
                        .speakText(l10n.translate('registration.sowingTitle')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.translate('registration.sowingTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.translate('registration.sowingBody'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SowingTile(
                    label: l10n.translate('sowing.thisMonth'),
                    selected: _selectedOption == 0,
                    onTap: () => setState(() {
                      _sowingDate = now;
                      _selectedOption = 0;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SowingTile(
                    label: l10n.translate('sowing.lastMonth'),
                    selected: _selectedOption == 1,
                    onTap: () => setState(() {
                      _sowingDate = DateTime(now.year, now.month - 1, now.day);
                      _selectedOption = 1;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SowingTile(
                    label: l10n.translate('sowing.twoMonthsAgo'),
                    selected: _selectedOption == 2,
                    onTap: () => setState(() {
                      _sowingDate = DateTime(now.year, now.month - 2, now.day);
                      _selectedOption = 2;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SowingTile(
                    label: l10n.translate('sowing.pickDate'),
                    selected: _selectedOption == 3,
                    onTap: () => _pickDate(context),
                  ),
                  if (days != null) ...[
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
                        l10n
                            .translate('registration.stageBanner')
                            .replaceFirst('{stage}',
                                l10n.translate(stageKeyForDays(days)))
                            .replaceFirst('{day}', '$days'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sowingDate == null
                          ? null
                          : () {
                              ref
                                  .read(parcelDraftProvider.notifier)
                                  .setSowingDate(_sowingDate!);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WaterSourceScreen(),
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

class _SowingTile extends StatelessWidget {
  const _SowingTile(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            if (selected)
              const Icon(Icons.check, color: AppColors.seed, size: 18),
          ],
        ),
      ),
    );
  }
}
