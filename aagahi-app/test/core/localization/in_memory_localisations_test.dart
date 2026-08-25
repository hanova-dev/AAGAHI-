import 'package:aagahi/core/localization/in_memory_localisations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one invariant that matters most here: an unknown key must never
/// crash the app. Before this class existed in both build variants, the
/// real (non-demo) composition root left `localisationProvider` entirely
/// unwired, so any missing translation - or the whole provider - surfaced
/// as `UnimplementedError` on launch. A visible untranslated key is a bug
/// that can be seen and fixed; a crash is a product a board member cannot
/// evaluate at all.
void main() {
  group('translate', () {
    test('returns the key itself for an unknown key, and does not throw', () {
      const l10n = InMemoryLocalisations();

      expect(
        () => l10n.translate('totally.unknown.key'),
        returnsNormally,
      );
      expect(l10n.translate('totally.unknown.key'), 'totally.unknown.key');
    });

    test('returns the Urdu translation for a known key in the Urdu locale', () {
      const l10n = InMemoryLocalisations(BuiltinLocale.ur);
      expect(
        l10n.translate('advisory.irrigateNow'),
        'اگر ممکن ہو تو ابھی پانی دیں',
      );
    });

    test('returns the English translation for a known key in the English locale', () {
      const l10n = InMemoryLocalisations(BuiltinLocale.en);
      expect(l10n.translate('advisory.irrigateNow'), 'Irrigate now if you can');
    });
  });
}
