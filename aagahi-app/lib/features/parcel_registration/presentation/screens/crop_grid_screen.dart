import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/crop_catalog.dart';
import '../providers/parcel_registration_providers.dart';
import 'sowing_date_screen.dart';

const _categoryTitleKeys = {
  CropCategory.cereals: 'category.cereals',
  CropCategory.pulsesOilseeds: 'category.pulsesOilseeds',
  CropCategory.vegetables: 'category.vegetables',
  CropCategory.fruits: 'category.fruits',
  CropCategory.fodder: 'category.fodder',
};

/// Screens B3a-B3d (screens_v2.html flow B) - one crop picture grid per
/// built category, parameterised rather than duplicated four times: the
/// only real difference between them is which crops show and whether the
/// orchard banner applies.
class CropGridScreen extends StatefulWidget {
  const CropGridScreen({required this.category, super.key});

  final CropCategory category;

  @override
  State<CropGridScreen> createState() => _CropGridScreenState();
}

class _CropGridScreenState extends State<CropGridScreen> {
  final _searchController = TextEditingController();
  String? _selectedCropId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final query = _searchController.text.trim().toLowerCase();
        final crops = cropCatalog.where((c) {
          if (c.category != widget.category) return false;
          if (query.isEmpty) return true;
          return l10n.translate(c.nameKey).toLowerCase().contains(query);
        }).toList(growable: false);
        final selected =
            _selectedCropId == null ? null : cropById(_selectedCropId!);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back,
                                color: AppColors.ink),
                          ),
                          Text(
                            l10n.translate(
                                _categoryTitleKeys[widget.category]!),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.ink),
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.search, color: AppColors.ink3),
                          hintText:
                              l10n.translate('registration.searchCropHint'),
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
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      final isSelected = crop.id == _selectedCropId;
                      return InkWell(
                        onTap: () => setState(() => _selectedCropId = crop.id),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.seed.withValues(alpha: 0.15)
                                : AppColors.glass,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.seed : AppColors.edge,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(crop.icon,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                l10n.translate(crop.nameKey),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.category == CropCategory.fruits)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(color: AppColors.edge),
                      ),
                      child: Text(
                        l10n.translate('registration.orchardBanner'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected == null
                          ? null
                          : () {
                              ref
                                  .read(parcelDraftProvider.notifier)
                                  .setCrop(selected.id);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SowingDateScreen(),
                                ),
                              );
                            },
                      child: Text(
                        selected == null
                            ? l10n.translate('action.next')
                            : l10n.translate('action.chooseCrop').replaceFirst(
                                '{crop}', l10n.translate(selected.nameKey)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
