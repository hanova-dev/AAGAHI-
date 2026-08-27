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
/// Layout, not tuned percentages: the value and caption are measured with a
/// [TextPainter] at the real [MediaQuery] text scale and font before anything
/// is positioned, and the trace's plotting band is whatever vertical space is
/// left over inside the arc once that measured text block and a mandatory
/// gap are reserved. If the measured caption would not leave room for even a
/// legible minimum trace band - Nastaliq at 200% scale is the case this
/// exists for - the caption is pushed below the ring entirely rather than
/// letting anything overlap or clip. See [captionStyle] for how a caller
/// exercises real Urdu typography here rather than a placeholder font.
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
    this.captionStyle,
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

  /// Overrides the caption's font/height, merged over the built-in default
  /// (`TextStyle.merge` - fields the caller doesn't set fall back to the
  /// default). Pass `AppTheme.urdu` for an Urdu caption: its Nastaliq family
  /// and 2.05 line height are exactly what this widget's layout math has to
  /// measure and plan around, and a plain Latin style would silently test
  /// the wrong font.
  final TextStyle? captionStyle;

  static const _defaultCaptionStyle = TextStyle(
    letterSpacing: 1.4,
    color: AppColors.ink3,
    fontWeight: FontWeight.w600,
  );

  /// Minimum height for a legible trace: below this the curve's shape stops
  /// being readable regardless of ring size. Tied to half the app's minimum
  /// touch target (AppSpacing.minTouchTarget) as a real, reused unit rather
  /// than a fraction invented for this widget.
  static const _minTraceBandHeight = AppSpacing.minTouchTarget / 2;

  /// The gap CON-... UI-EXT-07 style requirements imply but don't name: the
  /// trace and the text block must never be closer than this, at any scale.
  static const _minGap = AppSpacing.sm;
  static const _textBlockGap = AppSpacing.xs;
  static const _bottomMargin = AppSpacing.xs;

  double _measureLineHeight(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    return painter.height;
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    // Beyond ~1.3x the numerals alone start crowding the arc; easing the
    // font size down here reduces how often the caption-eviction fallback
    // below has to trigger at all. It is a soft measure, not the safety net -
    // the measured-height computation that follows is what actually
    // guarantees no overlap or clip.
    final useCompactText = textScaler.scale(1.0) > 1.3;

    final valueText = '${(probability * 100).round()}%';
    final valueStyle = TextStyle(
      fontSize: useCompactText ? size * 0.11 : size * 0.135,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      color: AppColors.ink,
    );
    final resolvedCaptionStyle = _defaultCaptionStyle
        .copyWith(fontSize: size * 0.042)
        .merge(captionStyle);

    final valueHeight = _measureLineHeight(valueText, valueStyle, textScaler);
    final captionHeight = caption == null
        ? 0.0
        : _measureLineHeight(caption!, resolvedCaptionStyle, textScaler);

    // --- ring geometry: driven by width alone, never by text metrics ------
    const baseHeightRatio = 0.68;
    final baseHeight = size * baseHeightRatio;
    final strokeWidth = size * 0.055;
    final radius = (size - strokeWidth) / 2;
    final centreDy = baseHeight - strokeWidth / 2;
    // "Just inside the arc stroke" down to the floor where the arc's two
    // ends sit - a dimension expressed in the stroke's own width, not a
    // fraction of the whole widget tuned to look right at one size.
    final domeInteriorHeight = radius - strokeWidth * 1.2;

    // --- does the caption fit inside the ring at this scale? ---------------
    final withCaptionHeight = caption == null
        ? valueHeight
        : valueHeight + _textBlockGap + captionHeight;
    final requiredWithCaption =
        _minTraceBandHeight + _minGap + withCaptionHeight + _bottomMargin;
    final captionFitsInsideRing =
        caption == null || domeInteriorHeight >= requiredWithCaption;

    final textBlockHeight =
        captionFitsInsideRing ? withCaptionHeight : valueHeight;
    final requiredHeight =
        _minTraceBandHeight + _minGap + textBlockHeight + _bottomMargin;

    // The dome's own shape never shrinks or grows with text; if the text
    // block needs more room than the dome interior offers even after taking
    // every fallback available, the *floor* below the dome grows instead of
    // letting anything clip.
    final extraFloorSpace = math.max(0.0, requiredHeight - domeInteriorHeight);
    final totalRingHeight = baseHeight + extraFloorSpace;

    final traceBandHeight = math.max(
      _minTraceBandHeight,
      domeInteriorHeight +
          extraFloorSpace -
          _minGap -
          textBlockHeight -
          _bottomMargin,
    );
    final traceTop = centreDy - radius + strokeWidth * 1.2;
    final traceBottom = traceTop + traceBandHeight;
    final textTop =
        centreDy + extraFloorSpace - _bottomMargin - textBlockHeight;

    final ring = SizedBox(
      width: size,
      height: totalRingHeight,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size, totalRingHeight),
            painter: _RiskRingPainter(
              probability: probability,
              bandColor: AppColors.forBand(band),
              trace: trace,
              trackColor: AppColors.edge,
              centre: Offset(size / 2, centreDy),
              radius: radius,
              strokeWidth: strokeWidth,
              traceTop: traceTop,
              traceBottom: traceBottom,
            ),
          ),
          Positioned(
            top: textTop,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: valueStyle,
                ),
                if (captionFitsInsideRing && caption != null) ...[
                  const SizedBox(height: _textBlockGap),
                  Text(
                    caption!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: resolvedCaptionStyle,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring,
          if (!captionFitsInsideRing && caption != null) ...[
            const SizedBox(height: _textBlockGap),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: resolvedCaptionStyle,
            ),
          ],
        ],
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
    required this.centre,
    required this.radius,
    required this.strokeWidth,
    required this.traceTop,
    required this.traceBottom,
  });

  final double probability;
  final Color bandColor;
  final List<TracePoint> trace;
  final Color trackColor;
  final Offset centre;
  final double radius;
  final double strokeWidth;

  /// The trace's plotting band, already computed in [RiskRing.build] from
  /// the measured text block height so it can never collide with the
  /// numerals or caption below it.
  final double traceTop;
  final double traceBottom;

  /// Semicircle sweep, drawn from 180 degrees clockwise through 180 degrees.
  static const double _startAngle = math.pi;
  static const double _sweepAngle = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
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
    _paintTrace(canvas);
  }

  void _paintTrace(Canvas canvas) {
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

    final plotWidth = radius * 1.05;
    final left = centre.dx - plotWidth / 2;
    final bottom = traceBottom;
    final top = traceTop;

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
      oldDelegate.traceTop != traceTop ||
      oldDelegate.traceBottom != traceBottom ||
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
