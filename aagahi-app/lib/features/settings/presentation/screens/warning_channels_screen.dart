import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';

/// Screen H3 (screens_v2.html flow H) - warning channels and quiet hours,
/// persisted to Drift.
///
/// Channel order is fixed (WhatsApp, App notification, SMS, Voice call),
/// matching the reference exactly - there is no drag-to-reorder affordance
/// in the mockup, so building one would be UI nobody asked for.
class WarningChannelsScreen extends ConsumerWidget {
  const WarningChannelsScreen({super.key});

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay _parse(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// One tap picks both ends of the quiet-hours window in sequence - start,
  /// then end - rather than two separate tap targets for a single concept.
  Future<void> _pickQuietHours(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _parse(settings.quietHoursStart),
      helpText: 'QUIET HOURS START',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _parse(settings.quietHoursEnd),
      helpText: 'QUIET HOURS END',
    );
    if (end == null) return;
    await ref.read(settingsRepositoryProvider).save(
          settings.copyWith(
              quietHoursStart: _format(start), quietHoursEnd: _format(end)),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;

    void toggle(AppSettings Function(AppSettings, bool) apply, bool value) {
      if (settings == null) return;
      ref.read(settingsRepositoryProvider).save(apply(settings, value));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Expanded(
                  child: Text(
                    l10n.translate('settings.warningChannels'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.translate('settings.channelsIntro'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _ChannelRow(
              order: 1,
              label: l10n.translate('settings.channel.whatsapp'),
              value: settings?.whatsappEnabled ?? true,
              onChanged: settings == null
                  ? null
                  : (v) => toggle((s, v) => s.copyWith(whatsappEnabled: v), v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChannelRow(
              order: 2,
              label: l10n.translate('settings.channel.appNotification'),
              value: settings?.appNotificationEnabled ?? true,
              onChanged: settings == null
                  ? null
                  : (v) => toggle(
                      (s, v) => s.copyWith(appNotificationEnabled: v), v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChannelRow(
              order: 3,
              label: l10n.translate('settings.channel.sms'),
              value: settings?.smsEnabled ?? true,
              onChanged: settings == null
                  ? null
                  : (v) => toggle((s, v) => s.copyWith(smsEnabled: v), v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChannelRow(
              order: 4,
              label: l10n.translate('settings.channel.voiceCall'),
              value: settings?.voiceCallEnabled ?? false,
              onChanged: settings == null
                  ? null
                  : (v) => toggle((s, v) => s.copyWith(voiceCallEnabled: v), v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('settings.quietHours'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: settings == null
                  ? null
                  : () => _pickQuietHours(context, ref, settings),
              child: _QuietHoursField(
                label: l10n.translate('settings.noMessagesBetween'),
                value: settings == null
                    ? '—'
                    : '${settings.quietHoursStart} — ${settings.quietHoursEnd}',
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
                l10n.translate('settings.maxWarningsBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.order,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final int order;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.edge),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.seed.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$order',
              style: const TextStyle(
                color: AppColors.seed,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.titleMedium)),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.seed),
        ],
      ),
    );
  }
}

class _QuietHoursField extends StatelessWidget {
  const _QuietHoursField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.edge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
