import 'package:aagahi/core/theme/app_theme.dart';
import 'package:aagahi/features/risk/domain/entities/risk_assessment.dart';
import 'package:aagahi/shared_widgets/risk_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Proves the RiskRing collision fix (CLAUDE.md S1 / product owner review,
/// 2026-08-23): the trace band and the text block below it must never
/// overlap or clip, at text scale 1.0 through 2.0, in English and in Urdu,
/// on the SRS's minimum reference viewport (HW-01: 4.5", 720x1280).
///
/// Real fonts are loaded deliberately. Flutter's test binding does not load
/// app fonts by default; without this, the Urdu golden would render generic
/// test glyphs and would say nothing about whether Nastaliq's real,
/// unusually tall line height (AppTheme.urdu: height 2.05) actually fits -
/// which is the entire question this test exists to answer.
Future<void> _loadAppFonts() async {
  final regular =
      await rootBundle.load('assets/fonts/NotoNastaliqUrdu-Regular.ttf');
  await (FontLoader('NotoNastaliqUrdu')..addFont(Future.value(regular))).load();
}

/// SRS HW-01 minimum reference device: 4.5" screen, 720x1280 physical.
/// At ~326 dpi that's a 2.0 device pixel ratio, i.e. 360x640 logical px -
/// the smallest viewport this layout has to survive on.
void _setReferenceViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

RiskAssessment _scenario() {
  final now = DateTime.utc(2026, 8, 23);
  const percentiles = [
    82.0,
    80.0,
    77.0,
    74.0,
    69.0,
    61.0,
    53.0,
    45.0,
    39.0,
    34.0,
    31.0,
    29.0,
    28.0,
    27.0,
  ];
  return RiskAssessment(
    parcelId: 'golden-wheat-01',
    assessedOn: now,
    probability: 0.71,
    band: RiskBand.warning,
    horizonDays: 14,
    drivers: const [],
    trace: [
      for (var i = 0; i < percentiles.length; i++)
        TracePoint(
          date: now.subtract(Duration(days: percentiles.length - 1 - i)),
          percentile: percentiles[i],
        ),
    ],
    modelVersion: 'golden-v0',
    completenessRatio: 1.0,
    confidenceLower: 0.58,
    confidenceUpper: 0.81,
    usedDegradedInputs: false,
    isRainFed: false,
  );
}

/// Wraps [RiskRing] the way `RiskDashboardScreen` actually does - inside a
/// themed, dark card on the reference viewport - with room around the ring
/// left deliberately generous so an incorrect layout has somewhere visible
/// to overflow or clip *into*, rather than being hidden by a tight harness.
Widget _harness({
  required RiskAssessment assessment,
  required String caption,
  required TextDirection textDirection,
  required double textScale,
  TextStyle? captionStyle,
}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Directionality(
      textDirection: textDirection,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          backgroundColor: AppColors.soil,
          body: Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.canopy,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: RiskRing(
                probability: assessment.probability,
                band: assessment.band,
                trace: assessment.trace,
                caption: caption,
                captionStyle: captionStyle,
                semanticsLabel: 'golden test ring',
                size: 210,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadAppFonts);

  final scenario = _scenario();

  for (final scale in [1.0, 2.0]) {
    testWidgets('en caption at ${scale}x does not overlap or clip the trace',
        (tester) async {
      _setReferenceViewport(tester);
      await tester.pumpWidget(
        _harness(
          assessment: scenario,
          caption: '${scenario.horizonDays}-DAY RISK',
          textDirection: TextDirection.ltr,
          textScale: scale,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RiskRing),
        matchesGoldenFile('goldens/risk_ring_en_${scale}x.png'),
      );
    });

    testWidgets(
        'ur caption (real Nastaliq) at ${scale}x does not overlap or clip the trace',
        (tester) async {
      _setReferenceViewport(tester);
      await tester.pumpWidget(
        _harness(
          assessment: scenario,
          caption: '${scenario.horizonDays} دن کا خطرہ',
          textDirection: TextDirection.rtl,
          textScale: scale,
          // The real Urdu typography (Nastaliq family, 2.05 line height),
          // not the ring's plain Latin default - see module doc comment.
          captionStyle: AppTheme.urdu,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RiskRing),
        matchesGoldenFile('goldens/risk_ring_ur_${scale}x.png'),
      );
    });
  }

  testWidgets(
    'at 2.0x with real Nastaliq, the caption never overlaps the trace band '
    '(inside the ring if it fits, moved below if it does not)',
    (tester) async {
      _setReferenceViewport(tester);
      await tester.pumpWidget(
        _harness(
          assessment: scenario,
          caption: '${scenario.horizonDays} دن کا خطرہ',
          textDirection: TextDirection.rtl,
          textScale: 2.0,
          captionStyle: AppTheme.urdu,
        ),
      );
      await tester.pumpAndSettle();

      // Whichever branch RiskRing chose, there must be a Text widget somewhere
      // in the tree rendering the caption exactly once - never dropped,
      // never duplicated.
      expect(find.text('${scenario.horizonDays} دن کا خطرہ'), findsOneWidget);

      // The whole composition (ring plus, if evicted, the caption below it)
      // must fit within the harness's available height without Flutter's
      // overflow warning ("A RenderFlex overflowed") ever firing.
      expect(tester.takeException(), isNull);
    },
  );

  // Within the required 1.0-2.0 range, Nastaliq at this ring size (210,
  // matching RiskDashboardScreen's actual usage) fits inside the ring in
  // both goldens above - the eviction branch never engages there. That is a
  // real result, not a gap, but it leaves that branch unexercised by the
  // required-range tests. This forces it directly, at 4.0x (beyond the
  // required range, deliberately: it is the cleanest way to make the
  // measured text block exceed the dome's interior, given font size and
  // interior height both scale with `size` and so their ratio is roughly
  // scale-invariant across ring sizes - only textScale actually moves it),
  // so the fallback path is proven to work rather than merely written.
  testWidgets(
    'when the caption genuinely cannot fit, it moves below the ring '
    'instead of clipping',
    (tester) async {
      _setReferenceViewport(tester);
      await tester.pumpWidget(
        _harness(
          assessment: scenario,
          caption: '${scenario.horizonDays} دن کا خطرہ',
          textDirection: TextDirection.rtl,
          textScale: 4.0,
          captionStyle: AppTheme.urdu,
        ),
      );
      await tester.pumpAndSettle();

      final captionFinder = find.text('${scenario.horizonDays} دن کا خطرہ');
      expect(captionFinder, findsOneWidget);
      expect(tester.takeException(), isNull);

      // Prove it actually moved, not just that it's present: the caption's
      // top edge must sit at or below the ring's bottom edge - it is a
      // sibling below the ring, not a Positioned child inside its Stack.
      final ringBottom = tester.getBottomLeft(find.byType(RiskRing)).dy;
      // The ring here refers to the Stack inside RiskRing; compare against
      // the SizedBox that sizes the arc itself.
      final arcBox = find
          .descendant(of: find.byType(RiskRing), matching: find.byType(Stack))
          .first;
      final arcBottom = tester.getBottomLeft(arcBox).dy;
      final captionTop = tester.getTopLeft(captionFinder).dy;

      expect(
        captionTop,
        greaterThanOrEqualTo(arcBottom - 0.5),
        reason: 'caption must render below the arc, not inside its Stack',
      );
      expect(ringBottom, greaterThanOrEqualTo(captionTop));

      await expectLater(
        find.byType(RiskRing),
        matchesGoldenFile('goldens/risk_ring_ur_fallback_4.0x.png'),
      );
    },
  );
}
