import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/risk/domain/entities/risk_assessment.dart';

/// The product's signature visual.
///
/// Most risk gauges render a single number as a filled arc. This one draws the
/// actual soil-moisture percentile trace of the recent past *inside* the arc,
/// so the farmer sees the slope rather than the score. The rate of decline is
/// the entire scientific thesis of AAGAHI; the primary visual should carry it.
///
/// Accessibility: the ring is decorative in the semantic tree. The band, the
/// value, and the trend are announced through a single composed semantics
/// label so a screen reader speaks one coherent sentence instead of reading
/// out disconnected fragments.
class RiskRing extends StatelessWidget {
  const RiskRing({
    required this.probability,
    required this.band,
    required this.trace,
    required this.semanticsLabel,
    this.size = 200,
    this.caption,
    super.key,
  })  : assert(probability >= 0.0 && probability <= 1.0),
        assert(size > 0);

  final double probability;
  final RiskBand band;
  final List<TracePoint> trace;

  /// Fully composed, already-localised sentence, e.g. "Warning. Sixty-eight
  /// percent risk over fourteen days. Soil moisture falling."
  final String semanticsLabel;

  final double size;

  /// Small label under the value, already localised, e.g. "14-DAY RISK".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    // Respect the OS font scale, but cap it: beyond ~1.3x the numerals stop
    // fitting inside the ring and the layout must switch to the text-only
    // fallback rather than overflow (NFR-USE-005).
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final useCompactText = scale > 1.3;

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size * 0.68,
        child: CustomPaint(
          painter: _RiskRingPainter(
            probability: probability,
            bandColor: AppColors.forBand(band),
            trace: trace,
            trackColor: AppColors.edge,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(probability * 100).round()}%',
                    style: TextStyle(
                      fontSize: useCompactText ? size * 0.11 : size * 0.135,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppColors.ink,
                    ),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: size * 0.042,
                        letterSpacing: 1.4,
                        color: AppColors.ink3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiskRingPainter extends CustomPainter {
  const _RiskRingPainter({
    required this.probability,
    required this.bandColor,
    required this.trace,
    required this.trackColor,
  });

  final double probability;
  final Color bandColor;
  final List<TracePoint> trace;
  final Color trackColor;

  /// Semicircle sweep, drawn from 180 degrees clockwise through 180 degrees.
  static const double _startAngle = math.pi;
  static const double _sweepAngle = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.055;
    final radius = (size.width - strokeWidth) / 2;
    final centre = Offset(size.width / 2, size.height - strokeWidth / 2);
    final rect = Rect.fromCircle(center: centre, radius: radius);

    // --- track ---------------------------------------------------------
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    // --- value arc, graded low -> band colour ---------------------------
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [AppColors.low, AppColors.watch, bandColor],
        stops: const [0.0, 0.55, 1.0],
        transform: const GradientRotation(_startAngle),
      ).createShader(rect);

    // Clamp so a zero-probability arc still shows a visible cap rather than
    // vanishing, which would be indistinguishable from a failed render.
    final sweep = (_sweepAngle * probability).clamp(0.02, _sweepAngle);
    canvas.drawArc(rect, _startAngle, sweep, false, valuePaint);

    // --- the trace: this is the part that matters -----------------------
    _paintTrace(canvas, centre, radius, strokeWidth);
  }

  void _paintTrace(
    Canvas canvas,
    Offset centre,
    double radius,
    double strokeWidth,
  ) {
    if (trace.length < 2) return;

    final percentiles = trace.map((p) => p.percentile).toList(growable: false);
    final minimum = percentiles.reduce(math.min);
    final maximum = percentiles.reduce(math.max);
    final span = (maximum - minimum).abs();

    // A flat line is meaningful information - it means "not drying". Render it
    // mid-height rather than dividing by zero or hiding it.
    final normalise = span < 1e-6
        ? (double _) => 0.5
        : (double value) => (value - minimum) / span;

    // Inset the plotting area well inside the arc so the trace never collides
    // with the stroke or the numerals.
    final plotWidth = radius * 1.05;
    final plotHeight = radius * 0.42;
    final left = centre.dx - plotWidth / 2;
    final bottom = centre.dy - strokeWidth * 1.1;
    final top = bottom - plotHeight;

    final path = Path();
    for (var i = 0; i < trace.length; i++) {
      final x = left + (plotWidth * i / (trace.length - 1));
      final y = bottom - (normalise(percentiles[i]) * (bottom - top));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = bandColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, radius * 0.026)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Head marker on the most recent reading, so "where we are now" on the
    // curve is unambiguous.
    final lastX = left + plotWidth;
    final lastY = bottom - (normalise(percentiles.last) * (bottom - top));
    canvas.drawCircle(
      Offset(lastX, lastY),
      math.max(3.0, radius * 0.036),
      Paint()..color = bandColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskRingPainter oldDelegate) =>
      oldDelegate.probability != probability ||
      oldDelegate.bandColor != bandColor ||
      oldDelegate.trackColor != trackColor ||
      !identical(oldDelegate.trace, trace);
}

/// Band chip: colour, glyph shape, and word together.
class BandChip extends StatelessWidget {
  const BandChip({required this.band, required this.label, super.key});

  final RiskBand band;

  /// Already-localised band name.
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forBand(band);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(10, 10),
              painter: _GlyphPainter(glyph: band.glyph, color: color),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.glyph, required this.color});

  final BandGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    switch (glyph) {
      case BandGlyph.circle:
        canvas.drawCircle(Offset(w / 2, h / 2), w / 2, paint);
      case BandGlyph.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            const Radius.circular(2),
          ),
          paint,
        );
      case BandGlyph.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w, h)
            ..lineTo(0, h)
            ..close(),
          paint,
        );
      case BandGlyph.pentagon:
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
          final x = w / 2 + (w / 2) * math.cos(angle);
          final y = h / 2 + (h / 2) * math.sin(angle);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
