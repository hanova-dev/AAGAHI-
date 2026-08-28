import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/in_memory_localisations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';

/// Screen H2 (screens_v2.html flow H) - language and voice.
///
/// Language switching is the same real mechanism A2 already uses
/// (`localisationProvider.notifier.state = ...`) - wired here, not
/// duplicated. The three voice toggles persist to Drift for real, but
/// only "Bigger text" has a visible effect today: `AagahiApp` watches it
/// and actually scales on-screen text. "Read screens aloud"/"Slower
/// speech" are honest, saved preferences for a TTS pipeline that isn't
/// built yet (voice stays manual-entry only this phase) - "Hear a
/// sample" ships the same "not available" state as F3's mic rather than
/// pretending to play anything.
class LanguageVoiceScreen extends ConsumerStatefulWidget {
  const LanguageVoiceScreen({super.key});

  @override
  ConsumerState<LanguageVoiceScreen> createState() =>
      _LanguageVoiceScreenState();
}

class _LanguageVoiceScreenState extends ConsumerState<LanguageVoiceScreen> {
  bool _sampleTried = false;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localisationProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final isUrdu =
        l10n is InMemoryLocalisations && l10n.locale == BuiltinLocale.ur;

    void selectLocale(BuiltinLocale locale) {
      ref.read(localisationProvider.notifier).state =
          InMemoryLocalisations(locale);
    }

    void updateSettings(AppSettings Function(AppSettings) mutate) {
      if (settings == null) return;
      ref.read(settingsRepositoryProvider).save(mutate(settings));
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
                    l10n.translate('settings.languageAndVoice'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('settings.languageSection'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _LangChip(
                    label: 'اردو',
                    selected: isUrdu,
                    onTap: () => selectLocale(BuiltinLocale.ur)),
                const _LangChip(
                    label: 'Roman Urdu', selected: false, onTap: null),
                _LangChip(
                  label: 'English',
                  selected: !isUrdu,
                  onTap: () => selectLocale(BuiltinLocale.en),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('settings.voiceSection'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ToggleRow(
              title: l10n.translate('settings.readScreensAloud'),
              subtitle: l10n.translate('settings.readScreensAloudSubtitle'),
              value: settings?.voiceAutoplay ?? true,
              onChanged: settings == null
                  ? null
                  : (value) =>
                      updateSettings((s) => s.copyWith(voiceAutoplay: value)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ToggleRow(
              title: l10n.translate('settings.slowerSpeech'),
              subtitle: l10n.translate('settings.slowerSpeechSubtitle'),
              value: settings?.voiceSlower ?? false,
              onChanged: settings == null
                  ? null
                  : (value) =>
                      updateSettings((s) => s.copyWith(voiceSlower: value)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ToggleRow(
              title: l10n.translate('settings.biggerText'),
              subtitle: l10n.translate('settings.biggerTextSubtitle'),
              value: settings?.biggerText ?? false,
              onChanged: settings == null
                  ? null
                  : (value) =>
                      updateSettings((s) => s.copyWith(biggerText: value)),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => setState(() => _sampleTried = true),
              child: Text(l10n.translate('action.hearSample')),
            ),
            if (_sampleTried) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.translate('voice.notAvailable'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.seed.withValues(alpha: 0.18)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: selected ? AppColors.seed : AppColors.edge),
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
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.seed,
          ),
        ],
      ),
    );
  }
}
