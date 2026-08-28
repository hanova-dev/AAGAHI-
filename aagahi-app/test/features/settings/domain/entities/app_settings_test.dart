import 'package:aagahi/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.defaults', () {
    test('matches screens_v2.html H2/H3 - not arbitrary values', () {
      const defaults = AppSettings.defaults;

      expect(defaults.phoneNumber, isNull);
      expect(defaults.voiceAutoplay, isTrue);
      expect(defaults.voiceSlower, isFalse);
      expect(defaults.biggerText, isFalse);
      expect(defaults.whatsappEnabled, isTrue);
      expect(defaults.appNotificationEnabled, isTrue);
      expect(defaults.smsEnabled, isTrue);
      expect(defaults.voiceCallEnabled, isFalse);
      expect(defaults.quietHoursStart, '21:00');
      expect(defaults.quietHoursEnd, '06:00');
    });
  });

  group('copyWith', () {
    test('changes only the given fields, leaving the rest untouched', () {
      const original = AppSettings.defaults;

      final updated =
          original.copyWith(phoneNumber: '3001234567', biggerText: true);

      expect(updated.phoneNumber, '3001234567');
      expect(updated.biggerText, isTrue);
      expect(updated.voiceAutoplay, original.voiceAutoplay);
      expect(updated.quietHoursStart, original.quietHoursStart);
    });
  });
}
