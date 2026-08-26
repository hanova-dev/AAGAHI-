import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared_widgets/glass_card.dart';
import '../../../../shared_widgets/listen_pill.dart';
import '../../domain/entities/risk_assessment.dart';
import '../providers/risk_providers.dart';

/// Screen D2 (screens_v2.html flow D) - the 14-day soil-moisture trace,
/// reached from D1 ([CausalExplanationScreen]) via "View 14-day trend".
///
/// [RiskRing] stays the app's one hand-rolled [CustomPainter] (CLAUDE.md
/// S2): this is a plain line chart, which is exactly what a chart package
/// is for, so it uses fl_chart rather than a second custom painter.
class TraceDetailScreen extends ConsumerWidget {
  const TraceDetailScreen({required this.assessment, super.key});

  final RiskAssessment assessment;

  /// Percentile drop from [daysBack] days before the latest reading to the
  /// latest reading itself. Positive means drying. When the trace is
  /// shorter than [daysBack] (some seeded parcels carry only a week of
  /// history), this falls back to the earliest point available rather than
  /// indexing out of range - the resulting fall is honestly "as much history
  /// as we have," not a fabricated 14-day figure.
  static double _fallOverDays(List<TracePoint> trace, int daysBack) {
    final referenceIndex = (trace.length - 1 - daysBack).clamp(0, trace.length - 1);
    return trace[referenceIndex].percentile - trace.last.percentile;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localisationProvider);
    final trace = assessment.trace;
    final fiveDayFall = _fallOverDays(trace, 5);
    final fourteenDayFall = _fallOverDays(trace, 14);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
                Text(
                  l10n.translate('trace.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('trace.soilMoisturePercentile'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(height: 140, child: _TraceChart(assessment: assessment)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.assessedOn(trace.first.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        l10n.assessedOn(trace.last.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _FallTile(
                    label: l10n.translate('trace.fiveDayFall'),
                    fall: fiveDayFall,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FallTile(
                    label: l10n.translate('trace.fourteenDayFall'),
                    fall: fourteenDayFall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Text(
                l10n.translate('trace.rapidDryingBanner'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ListenPill(
                label: l10n.listen,
                isPlaying: ref.watch(briefingPlaybackProvider).isPlaying,
                onPressed: () => ref
                    .read(briefingPlaybackProvider.notifier)
                    .toggle(assessment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceChart extends StatelessWidget {
  const _TraceChart({required this.assessment});

  final RiskAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final trace = assessment.trace;
    final color = AppColors.forBand(assessment.band);
    final lastIndex = trace.length - 1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.edge,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < trace.length; i++)
                FlSpot(i.toDouble(), trace[i].percentile),
            ],
            isCurved: false,
            color: color,
            barWidth: 2.8,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => index == lastIndex
                  ? FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0)
                  : FlDotCirclePainter(radius: 0, color: color, strokeWidth: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallTile extends StatelessWidget {
  const _FallTile({required this.label, required this.fall});

  final String label;
  final double fall;

  @override
  Widget build(BuildContext context) {
    final drying = fall > 0;
    final color = drying ? AppColors.warning : AppColors.low;
    final sign = fall >= 0 ? '−' : '+';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            '$sign${fall.abs().round()} pts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
