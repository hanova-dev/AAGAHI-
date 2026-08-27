import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../parcel_registration/presentation/screens/field_location_screen.dart';
import '../../../risk/presentation/providers/risk_providers.dart';

/// Screen A9 (screens_v2.html flow A) - role selection, the last onboarding
/// screen before flow B (parcel registration) begins.
///
/// Only "Farmer" is selectable. The officer console and field-validator
/// workflow are out of scope this phase (an established boundary all
/// session, not new here) - their tiles are shown, honestly disabled,
/// rather than routing to screens that don't exist.
class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('onboarding.roleTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _RoleTile(
                icon: '🌾',
                title: l10n.translate('role.farmer'),
                selected: true,
                enabled: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleTile(
                icon: '🗺️',
                title: l10n.translate('role.officer'),
                subtitle: l10n.translate('role.officerSubtitle'),
                selected: false,
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleTile(
                icon: '✍️',
                title: l10n.translate('role.validator'),
                subtitle: l10n.translate('role.validatorSubtitle'),
                selected: false,
                enabled: false,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const FieldLocationScreen()),
                  ),
                  child: Text(l10n.translate('action.continue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.enabled,
    this.subtitle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
