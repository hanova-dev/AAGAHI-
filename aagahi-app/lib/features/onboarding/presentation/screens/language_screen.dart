import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/in_memory_localisations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import 'intro_screen.dart';

/// Screen A2 (screens_v2.html flow A) - language choice.
///
/// The one screen in this app that shows English and Urdu labels together
/// regardless of the active locale, deliberately: choosing a language is
/// the entire point of this screen, so it must be legible before that
/// choice is made. Every other screen in the app resolves through
/// `AppLocalisations.translate` in the current locale only - see D1/D2's
/// screens for where this same question was decided the other way.
///
/// Roman Urdu is shown, per the reference, but disabled: `InMemoryLocalisations`
/// only has two variants (English, Urdu script) - see its own doc comment.
/// Offering a third option that silently behaves like one of the other two
/// would be exactly the kind of quiet misrepresentation CLAUDE.md S1 rules
/// out.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localisationProvider);
    // AppLocalisations has no `.locale` in its interface - only its one
    // implementation does. A safe cast here is simpler than adding an
    // interface member every other implementation would have to define
    // too, for a question only this one screen ever asks.
    final isUrdu = current is InMemoryLocalisations ? current.locale == BuiltinLocale.ur : true;

    void selectAndAdvance(BuiltinLocale locale) {
      ref.read(localisationProvider.notifier).state =
          InMemoryLocalisations(locale);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const IntroScreen()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              const Text('Choose your language',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              const Text('اپنی زبان چنیں',
                  style: TextStyle(color: AppColors.ink2, fontSize: 14)),
              const SizedBox(height: AppSpacing.lg),
              _LanguageTile(
                title: 'اردو',
                subtitle: 'Urdu · voice ready',
                selected: isUrdu,
                onTap: () => selectAndAdvance(BuiltinLocale.ur),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _LanguageTile(
                title: 'Roman Urdu',
                subtitle: 'Urdu likha Angrezi mein - not built yet',
                selected: false,
                onTap: null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _LanguageTile(
                title: 'English',
                subtitle: 'For officers and validators',
                selected: !isUrdu,
                onTap: () => selectAndAdvance(BuiltinLocale.en),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
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
          border: Border.all(color: selected ? AppColors.seed : AppColors.edge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: disabled ? AppColors.ink3 : AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (selected) const Icon(Icons.check, color: AppColors.seed),
          ],
        ),
      ),
    );
  }
}
