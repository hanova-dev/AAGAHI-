import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../risk/presentation/providers/risk_providers.dart';
import '../../domain/entities/alert.dart';
import '../providers/alerts_providers.dart';
import 'alert_detail_screen.dart';

/// Screen E1 (screens_v2.html flow E) - the alert inbox, seeded from
/// [alertsProvider].
class AlertListScreen extends ConsumerWidget {
  const AlertListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final alerts = ref.watch(alertsProvider);
    final newCount = alerts.where((a) => !a.acknowledged).length;

    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.translate('nav.warnings'), style: Theme.of(context).textTheme.displaySmall),
              if (newCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.seed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.seed.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '$newCount ${l10n.translate('alerts.newSuffix')}',
                    style: const TextStyle(
                      color: AppColors.seed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final alert in alerts)
            _AlertRow(
              alert: alert,
              l10n: l10n,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => AlertDetailScreen(alertId: alert.id)),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n
                .translate('alerts.monthlySummary')
                .replaceFirst('{count}', '${alerts.length}'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.l10n, required this.onTap});

  final Alert alert;
  final AppLocalisations l10n;
  final VoidCallback onTap;

  String _statusLine() {
    final now = DateTime.now().toUtc();
    final sameDay = now.difference(alert.issuedAt).inHours < 24 && now.day == alert.issuedAt.day;
    final when = sameDay
        ? 'Today ${DateFormat('HH:mm').format(alert.issuedAt)}'
        : DateFormat('d MMM').format(alert.issuedAt);
    final channelKey = switch (alert.channel) {
      AlertChannel.push => 'alerts.channel.push',
      AlertChannel.whatsapp => 'alerts.channel.whatsapp',
      AlertChannel.sms => 'alerts.channel.sms',
    };
    final status = l10n
        .translate(alert.statusKey)
        .replaceFirst('{seconds}', '${alert.briefingDurationSeconds ?? 0}');
    return '$when · ${l10n.translate(channelKey)} · $status';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.forBand(alert.band),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.translate(alert.headlineKey)} · ${alert.parcelName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(_statusLine(), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
