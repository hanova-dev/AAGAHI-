import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/in_memory_localisations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../parcel_registration/presentation/providers/parcel_registration_providers.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../../risk/presentation/screens/parcel_switcher_view.dart';
import '../../../sync/presentation/screens/sync_status_screen.dart';
import '../providers/settings_providers.dart';
import 'data_privacy_screen.dart';
import 'language_voice_screen.dart';
import 'sources_licences_screen.dart';
import 'warning_channels_screen.dart';
import 'what_this_cannot_do_screen.dart';

/// Formats a raw, digits-only phone number the way the reference masks it
/// ("+92 300 4••• •••") - shows enough to be recognisable, hides the rest.
String _maskPhone(String stored) {
  var digits = stored.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('92')) digits = digits.substring(2);
  if (digits.length < 4) return '+92 $digits';
  final areaCode = digits.substring(0, 3);
  final nextDigit = digits.substring(3, 4);
  return '+92 $areaCode $nextDigit••• •••';
}

/// Screen H1 (screens_v2.html flow H) - settings home.
///
/// Every subtitle here is computed from real state (registered parcel,
/// saved phone number, live settings) rather than the reference's fixed
/// demo copy ("Allah Ditta", "4 fields") - there is no farmer name
/// collected anywhere in this app, so none is shown; a device that hasn't
/// finished flow B/A7 yet shows an honest "not set" state instead.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final parcel = ref.watch(registeredParcelProvider).valueOrNull;
    final isUrdu =
        l10n is InMemoryLocalisations && l10n.locale == BuiltinLocale.ur;

    final phoneText = settings?.phoneNumber == null
        ? l10n.translate('settings.phoneNotSet')
        : _maskPhone(settings!.phoneNumber!);
    final languageName = isUrdu ? 'اردو' : 'English';
    final autoplayText = l10n.translate(
      (settings?.voiceAutoplay ?? true)
          ? 'settings.autoplayOn'
          : 'settings.autoplayOff',
    );
    final channelSummary = settings == null
        ? ''
        : '${l10n.translate('settings.whatsappFirst')} · '
            '${l10n.translate('settings.quietRange').replaceFirst('{start}', settings.quietHoursStart).replaceFirst('{end}', settings.quietHoursEnd)}';
    final fieldsCount = parcel == null ? 0 : 1;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(l10n.translate('settings.title'),
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.glassStrong,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.edge),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🌾', style: TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phoneText,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        l10n.translate('role.farmer'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsRow(
              icon: '🗣️',
              title: l10n.translate('settings.languageAndVoice'),
              subtitle: '$languageName · $autoplayText',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const LanguageVoiceScreen()),
              ),
            ),
            _SettingsRow(
              icon: '🔔',
              title: l10n.translate('settings.warningChannels'),
              subtitle: channelSummary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const WarningChannelsScreen()),
              ),
            ),
            _SettingsRow(
              icon: '🌾',
              title: l10n.translate('settings.myFields'),
              subtitle: fieldsCount == 0
                  ? l10n.translate('settings.myFieldsCountZero')
                  : l10n
                      .translate('settings.myFieldsCount')
                      .replaceFirst('{count}', '$fieldsCount'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ParcelSwitcherView()),
              ),
            ),
            _SettingsRow(
              icon: '🔒',
              title: l10n.translate('settings.dataAndPrivacy'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const DataPrivacyScreen()),
              ),
            ),
            _SettingsRow(
              icon: '📄',
              title: l10n.translate('settings.sources'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SourcesLicencesScreen()),
              ),
            ),
            _SettingsRow(
              icon: '⚠️',
              title: l10n.translate('settings.cannotDo'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const WhatThisCannotDoScreen()),
              ),
            ),
            // Not one of the reference's six H1 rows - flow G (sync
            // status/conflicts) has no entrance point of its own anywhere
            // in screens_v2.html, so this is the natural, minimal place to
            // add one rather than leaving G1/G2 unreachable code.
            _SettingsRow(
              icon: '🔄',
              title: l10n.translate('settings.syncStatus'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SyncStatusScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}
