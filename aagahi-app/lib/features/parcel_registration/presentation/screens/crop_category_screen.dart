import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/crop_catalog.dart';
import '../providers/parcel_registration_providers.dart';
import 'sowing_date_screen.dart';
import 'crop_grid_screen.dart';

const _categoryMeta = {
  CropCategory.cereals: ('🌾', 'category.cereals'),
  CropCategory.pulsesOilseeds: ('🫘', 'category.pulsesOilseeds'),
  CropCategory.vegetables: ('🥕', 'category.vegetables'),
  CropCategory.fruits: ('🥭', 'category.fruits'),
  CropCategory.fodder: ('🍀', 'category.fodder'),
};

/// Screen B3 (screens_v2.html flow B) - crop category chooser.
///
/// Typing in the search field jumps straight to a crop by name across all
/// four built categories - the manual-entry equivalent of the reference's
/// voice search (voice input stays out of scope this phase). [CropCategory.fodder]
/// has no picture grid behind it (see [CropCategory]'s doc comment), so its
/// tile is shown disabled rather than routing to fabricated crop names.
class CropCategoryScreen extends StatefulWidget {
  const CropCategoryScreen({super.key});

  @override
  State<CropCategoryScreen> createState() => _CropCategoryScreenState();
}

class _CropCategoryScreenState extends State<CropCategoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _chooseCrop(BuildContext context, WidgetRef ref, CropOption crop) {
    ref.read(parcelDraftProvider.notifier).setCrop(crop.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SowingDateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final query = _searchController.text.trim().toLowerCase();
        final matches = query.isEmpty
            ? const <CropOption>[]
            : cropCatalog
                .where((c) =>
                    l10n.translate(c.nameKey).toLowerCase().contains(query))
                .toList(growable: false);

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('registration.cropCategoryTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.ink3),
                      hintText: l10n.translate('registration.searchCropHint'),
                      hintStyle: const TextStyle(color: AppColors.ink3),
                      filled: true,
                      fillColor: AppColors.glass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: const BorderSide(color: AppColors.edge),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: query.isEmpty
                        ? ListView(
                            children: [
                              for (final category in CropCategory.values)
                                _CategoryTile(
                                  category: category,
                                  l10n: l10n,
                                  onTap: category == CropCategory.fodder
                                      ? null
                                      : () => Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => CropGridScreen(
                                                  category: category),
                                            ),
                                          ),
                                )
                            ],
                          )
                        : ListView(
                            children: [
                              for (final crop in matches)
                                ListTile(
                                  leading: Text(crop.icon,
                                      style: const TextStyle(fontSize: 22)),
                                  title: Text(
                                    l10n.translate(crop.nameKey),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  onTap: () => _chooseCrop(context, ref, crop),
                                ),
                              if (matches.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: AppSpacing.lg),
                                  child: Text(
                                    l10n.translate(
                                        'registration.noCropMatches'),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                            ],
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
      {required this.category, required this.l10n, required this.onTap});

  final CropCategory category;
  final AppLocalisations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, labelKey) = _categoryMeta[category]!;
    final count = category == CropCategory.fodder
        ? 6
        : cropCatalog.where((c) => c.category == category).length;
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.edge),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.translate(labelKey),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$count',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
