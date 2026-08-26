import 'package:equatable/equatable.dart';

import '../../../risk/domain/entities/risk_assessment.dart';

/// Delivery channel an alert went out on (FR-ALRT-004's ladder). Display
/// only here - there is no real delivery pipeline yet (outbox/sync are out
/// of scope for this phase).
enum AlertChannel { push, whatsapp, sms }

/// A single delivered warning, as the farmer sees it in the alert list and
/// detail screens (E1/E2).
///
/// Deliberately no repository interface behind this: every instance is
/// seeded, hand-authored demo content (see
/// `alerts/presentation/providers/alerts_providers.dart`), and an
/// abstraction with exactly one implementation and no test double is
/// structure with nothing to justify it (CLAUDE.md S2). When a real alert
/// backend exists, this is where that boundary gets added - not before.
final class Alert extends Equatable {
  const Alert({
    required this.id,
    required this.parcelName,
    required this.band,
    required this.issuedAt,
    required this.channel,
    required this.statusKey,
    required this.headlineKey,
    required this.adviceKey,
    this.briefingDurationSeconds,
    this.acknowledged = false,
  });

  final String id;
  final String parcelName;
  final RiskBand band;
  final DateTime issuedAt;
  final AlertChannel channel;

  /// Localisation key for the short status line under the headline in the
  /// list, e.g. "heard", "you replied", or a voice-duration template.
  final String statusKey;

  final String headlineKey;
  final String adviceKey;

  /// Null when no briefing was ever rendered for this alert (only
  /// WARNING+ alerts get one per FR-ALRT-007). Non-null does not mean the
  /// audio file is present on this device - see [AlertDetailScreen], which
  /// ships its player UI with the file absent on purpose.
  final int? briefingDurationSeconds;

  final bool acknowledged;

  Alert copyWith({bool? acknowledged, String? statusKey}) => Alert(
        id: id,
        parcelName: parcelName,
        band: band,
        issuedAt: issuedAt,
        channel: channel,
        statusKey: statusKey ?? this.statusKey,
        headlineKey: headlineKey,
        adviceKey: adviceKey,
        briefingDurationSeconds: briefingDurationSeconds,
        acknowledged: acknowledged ?? this.acknowledged,
      );

  @override
  List<Object?> get props => [
        id,
        parcelName,
        band,
        issuedAt,
        channel,
        statusKey,
        headlineKey,
        adviceKey,
        briefingDurationSeconds,
        acknowledged,
      ];
}
