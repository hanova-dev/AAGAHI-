import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../providers/parcel_registration_providers.dart';
import 'crop_category_screen.dart';

enum _AreaUnit { acre, kanal, marla, hectare }

/// Conversion to acres - the unit `Parcel.areaAcres` stores. 8 kanal = 160
/// marla = 1 acre is the standard Punjab land-measure relationship.
const _acresPerUnit = {
  _AreaUnit.acre: 1.0,
  _AreaUnit.kanal: 0.125,
  _AreaUnit.marla: 0.00625,
  _AreaUnit.hectare: 2.47105,
};

/// Screen B2 (screens_v2.html flow B) - field size.
///
/// The reference's "🎙️ Say it" button ships the same F3 "not available"
/// state as A7's phone-number mic, rather than being silently dropped -
/// manual entry (the text field beside it) is the one way to answer this
/// screen this phase.
class FieldSizeScreen extends StatefulWidget {
  const FieldSizeScreen({super.key});

  @override
  State<FieldSizeScreen> createState() => _FieldSizeScreenState();
}

class _FieldSizeScreenState extends State<FieldSizeScreen> {
  final _controller = TextEditingController(text: '3.5');
  _AreaUnit _unit = _AreaUnit.acre;
  bool _micTried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _valueInAcres {
    final value = double.tryParse(_controller.text);
    if (value == null || value <= 0) return null;
    return value * _acresPerUnit[_unit]!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = ref.watch(localisationProvider);
        final acres = _valueInAcres;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon:
                            const Icon(Icons.arrow_back, color: AppColors.ink),
                      ),
                    ],
                  ),
                  Text(
                    l10n.translate('registration.areaTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                      ],
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Center(
                    child: Text(
                      l10n.translate('registration.areaUnit'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _UnitChip(
                        label: 'Acre',
                        selected: _unit == _AreaUnit.acre,
                        onTap: () => setState(() => _unit = _AreaUnit.acre),
                      ),
                      _UnitChip(
                        label: 'Kanal',
                        selected: _unit == _AreaUnit.kanal,
                        onTap: () => setState(() => _unit = _AreaUnit.kanal),
                      ),
                      _UnitChip(
                        label: 'Marla',
                        selected: _unit == _AreaUnit.marla,
                        onTap: () => setState(() => _unit = _AreaUnit.marla),
                      ),
                      _UnitChip(
                        label: 'Hectare',
                        selected: _unit == _AreaUnit.hectare,
                        onTap: () => setState(() => _unit = _AreaUnit.hectare),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _micTried = true),
                          child: Text(l10n.translate('action.sayIt')),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: acres == null
                              ? null
                              : () {
                                  ref
                                      .read(parcelDraftProvider.notifier)
                                      .setArea(acres);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const CropCategoryScreen(),
                                    ),
                                  );
                                },
                          child: Text(l10n.translate('action.next')),
                        ),
                      ),
                    ],
                  ),
                  if (_micTried) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.translate('voice.notAvailable'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.seed.withValues(alpha: 0.18)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.seed : AppColors.edge),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.seed : AppColors.ink2,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
