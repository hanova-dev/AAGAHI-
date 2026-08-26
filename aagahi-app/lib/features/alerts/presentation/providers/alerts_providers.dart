import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../risk/domain/entities/risk_assessment.dart';
import '../../domain/entities/alert.dart';

/// Seeded alert history matching screens_v2.html flow E's E1 mockup
/// exactly (parcel names, bands, dates, channels, statuses) - not
/// arbitrary placeholder content.
final alertsProvider = NotifierProvider<AlertsNotifier, List<Alert>>(AlertsNotifier.new);

class AlertsNotifier extends Notifier<List<Alert>> {
  @override
  List<Alert> build() => [
        Alert(
          id: 'alert-1',
          parcelName: 'Chak 42/GB',
          band: RiskBand.warning,
          issuedAt: DateTime.now().toUtc(),
          channel: AlertChannel.whatsapp,
          statusKey: 'alerts.status.voiceSeconds',
          headlineKey: 'alerts.headline.rapidDrying',
          adviceKey: 'alerts.advice.cutWeeds',
          briefingDurationSeconds: 38,
        ),
        Alert(
          id: 'alert-2',
          parcelName: 'Kotli plot',
          band: RiskBand.watch,
          issuedAt: DateTime.now().toUtc().subtract(const Duration(days: 7)),
          channel: AlertChannel.push,
          statusKey: 'alerts.status.heard',
          headlineKey: 'alerts.headline.watchConditions',
          adviceKey: 'alerts.advice.keepMonitoring',
          acknowledged: true,
        ),
        Alert(
          id: 'alert-3',
          parcelName: 'Chak 42/GB',
          band: RiskBand.low,
          issuedAt: DateTime.now().toUtc().subtract(const Duration(days: 15)),
          channel: AlertChannel.push,
          statusKey: 'alerts.status.heard',
          headlineKey: 'alerts.headline.conditionsEased',
          adviceKey: 'alerts.advice.noActionNeeded',
          acknowledged: true,
        ),
        Alert(
          id: 'alert-4',
          parcelName: 'Nehri rakba',
          band: RiskBand.severe,
          issuedAt: DateTime.now().toUtc().subtract(const Duration(days: 24)),
          channel: AlertChannel.sms,
          statusKey: 'alerts.status.repliedByYou',
          headlineKey: 'alerts.headline.severeDrying',
          adviceKey: 'alerts.advice.cutWeeds',
          acknowledged: true,
        ),
      ];

  /// Marks an alert heard - a real local state change, not a no-op button:
  /// the list and detail screens both reflect it immediately. There is no
  /// backend to notify (outbox/sync are out of scope for this phase), so
  /// this does not attempt to.
  void acknowledge(String id) {
    state = [
      for (final alert in state)
        if (alert.id == id)
          alert.copyWith(acknowledged: true, statusKey: 'alerts.status.heard')
        else
          alert,
    ];
  }
}
