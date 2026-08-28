import 'package:equatable/equatable.dart';

/// The single persisted settings row (screens_v2.html flow H). There is
/// exactly one farmer per device this phase (no multi-profile switching),
/// so this is a singleton, not a keyed collection.
///
/// [voiceAutoplay]/[voiceSlower] are real, persisted preferences with no
/// effect yet: there is no TTS pipeline wired (voice stays manual-entry
/// only this phase, same boundary as flow A/F). Persisting a preference
/// for a feature that doesn't exist yet is not dishonest by itself -
/// nothing on screen claims the app is currently speaking - but it must
/// never be confused with the one voice-adjacent setting that *does* have
/// a real, visible effect today: [biggerText], which actually scales
/// on-screen text app-wide (see `AagahiApp`).
final class AppSettings extends Equatable {
  const AppSettings({
    required this.phoneNumber,
    required this.voiceAutoplay,
    required this.voiceSlower,
    required this.biggerText,
    required this.whatsappEnabled,
    required this.appNotificationEnabled,
    required this.smsEnabled,
    required this.voiceCallEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  /// The reasonable, honest defaults for a device that has never saved
  /// settings - matching screens_v2.html H2/H3's own toggle states, not
  /// arbitrary choices.
  static const defaults = AppSettings(
    phoneNumber: null,
    voiceAutoplay: true,
    voiceSlower: false,
    biggerText: false,
    whatsappEnabled: true,
    appNotificationEnabled: true,
    smsEnabled: true,
    voiceCallEnabled: false,
    quietHoursStart: '21:00',
    quietHoursEnd: '06:00',
  );

  /// Null until A7/A8 (onboarding) confirm one, or on a demo build that
  /// never runs onboarding - H1 shows an honest "not set" state rather
  /// than a fabricated number.
  final String? phoneNumber;

  final bool voiceAutoplay;
  final bool voiceSlower;
  final bool biggerText;

  final bool whatsappEnabled;
  final bool appNotificationEnabled;
  final bool smsEnabled;
  final bool voiceCallEnabled;

  /// 24-hour "HH:mm" strings, not `TimeOfDay` - the only thing that reads
  /// them is display code and `showTimePicker`'s own round trip, so there
  /// is nothing a richer stored type would buy here.
  final String quietHoursStart;
  final String quietHoursEnd;

  AppSettings copyWith({
    String? phoneNumber,
    bool? voiceAutoplay,
    bool? voiceSlower,
    bool? biggerText,
    bool? whatsappEnabled,
    bool? appNotificationEnabled,
    bool? smsEnabled,
    bool? voiceCallEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) =>
      AppSettings(
        phoneNumber: phoneNumber ?? this.phoneNumber,
        voiceAutoplay: voiceAutoplay ?? this.voiceAutoplay,
        voiceSlower: voiceSlower ?? this.voiceSlower,
        biggerText: biggerText ?? this.biggerText,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        appNotificationEnabled:
            appNotificationEnabled ?? this.appNotificationEnabled,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        voiceCallEnabled: voiceCallEnabled ?? this.voiceCallEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      );

  @override
  List<Object?> get props => [
        phoneNumber,
        voiceAutoplay,
        voiceSlower,
        biggerText,
        whatsappEnabled,
        appNotificationEnabled,
        smsEnabled,
        voiceCallEnabled,
        quietHoursStart,
        quietHoursEnd,
      ];
}
