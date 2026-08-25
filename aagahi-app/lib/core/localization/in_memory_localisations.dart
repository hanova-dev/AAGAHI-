import 'package:intl/intl.dart';

import '../../features/risk/domain/entities/risk_assessment.dart';
import '../../features/risk/presentation/providers/risk_providers.dart';

/// Which locale [InMemoryLocalisations] renders.
///
/// Not the three production locales (en / ur / ur-Roman - UI-EXT-02): this
/// is a two-value stand-in, chosen to be trivial to construct without a
/// locale-switcher UI, which is out of scope here.
enum BuiltinLocale { en, ur }

/// Minimal, hand-written, in-memory [AppLocalisations].
///
/// This is deliberately not the ARB/`flutter_localizations` pipeline
/// FR-LOCL-001 ultimately requires. It exists so neither build variant is
/// ever one `ref.watch(localisationProvider)` away from a hard crash before
/// that pipeline is built - see `main.dart`, which wires this for both
/// `--dart-define=DEMO=true` and the real (Drift+remote) composition root.
/// The string map inside `translate()` covers only the keys this app's
/// current seeded/demo content actually produces, not a general-purpose
/// translation table - `translate()` returns the raw key for anything else
/// rather than throwing (see its doc comment for why that matters).
///
/// The Urdu band framings in [bandLabel] are the exact "farmer-facing Urdu
/// framing" strings from the SRS (Appendix B), not phrases invented for
/// this file. Everything else in Urdu here is unreviewed placeholder copy -
/// do not treat it as satisfying FR-EXPL-005's native-speaker review
/// requirement, and do not ship it to real farmers as final narration text.
final class InMemoryLocalisations implements AppLocalisations {
  const InMemoryLocalisations([this.locale = BuiltinLocale.ur]);

  final BuiltinLocale locale;

  bool get _ur => locale == BuiltinLocale.ur;

  static const _translations = <String, ({String en, String ur})>{
    'driver.evaporativeDemand': (
      en: 'High evaporative demand is pulling moisture from the soil faster than usual.',
      ur: 'ہوا میں خشکی معمول سے زیادہ تیزی سے مٹی کی نمی ختم کر رہی ہے۔',
    ),
    'driver.rootZoneDrying': (
      en: 'Root-zone moisture has been falling fast over the last five days.',
      ur: 'پچھلے پانچ دنوں میں جڑوں کی گہرائی کی نمی تیزی سے کم ہوئی ہے۔',
    ),
    'driver.rainfallDeficit': (
      en: 'Rainfall over the last month has been below normal.',
      ur: 'پچھلے مہینے بارش معمول سے کم رہی ہے۔',
    ),
    'advisory.irrigateNow': (
      en: 'Irrigate now if you can',
      ur: 'اگر ممکن ہو تو ابھی پانی دیں',
    ),
  };

  @override
  String translate(String key) {
    final entry = _translations[key];
    // Falls back to the raw key rather than throwing, deliberately, even
    // though FR-LOCL-001 prohibits an untranslated fallback in the shipped
    // ARB pipeline: a visible key like "advisory.someNewThing" is a bug
    // that is immediately visible and fixable. Throwing here turns "one
    // string is missing" into "the screen is dead," which is exactly what
    // this project's own constitution rules out for a missing *reading* -
    // the same principle applies to a missing *label*.
    if (entry == null) return key;
    return _ur ? entry.ur : entry.en;
  }

  @override
  String get listen => _ur ? 'سنیں' : 'Listen';

  @override
  String get whatToDo => _ur ? 'کیا کریں' : 'What to do';

  @override
  String get whyIsItDrying => _ur ? 'یہ کیوں خشک ہو رہا ہے' : 'Why is it drying';

  @override
  String get howSureAreWe => _ur ? 'ہمیں کتنا یقین ہے' : 'How sure are we';

  @override
  String get tryAgain => _ur ? 'دوبارہ کوشش کریں' : 'Try again';

  @override
  String get degradedInputsNote =>
      _ur ? 'کچھ اعداد و شمار کا تخمینہ لگایا گیا ہے' : 'Some readings were estimated';

  @override
  String get notGuessingExplanation => _ur
      ? 'ہم صرف وہی بتاتے ہیں جو سیٹلائٹ واقعی دکھاتے ہیں۔ معلومات کافی نہ ہوں تو ہم اندازہ نہیں لگاتے۔'
      : 'We only tell you what the satellites actually show. If there is not '
          'enough data, we say so instead of guessing.';

  /// The exact "farmer-facing Urdu framing" column from the SRS (Appendix
  /// B: Risk Band Definitions) - not phrases invented for this file.
  @override
  String bandLabel(RiskBand band) => switch ((band, _ur)) {
        (RiskBand.low, true) => 'فی الحال خطرہ نہیں',
        (RiskBand.low, false) => 'No risk right now',
        (RiskBand.watch, true) => 'نظر رکھیں',
        (RiskBand.watch, false) => 'Keep watching',
        (RiskBand.warning, true) => 'خبردار رہیں',
        (RiskBand.warning, false) => 'Stay alert',
        (RiskBand.severe, true) => 'فوراً توجہ دیں',
        (RiskBand.severe, false) => 'Act immediately',
      };

  @override
  String confidenceLabel(ConfidenceLevel level) => switch ((level, _ur)) {
        (ConfidenceLevel.moderate, true) => 'درمیانہ',
        (ConfidenceLevel.moderate, false) => 'Moderate',
        (ConfidenceLevel.good, true) => 'اچھا',
        (ConfidenceLevel.good, false) => 'Good',
        (ConfidenceLevel.high, true) => 'زیادہ',
        (ConfidenceLevel.high, false) => 'High',
      };

  @override
  String horizonCaption(int days) => _ur ? '$days دن کا خطرہ' : '$days-DAY RISK';

  @override
  String rateSummary(RiskAssessment assessment) {
    if (assessment.trace.length < 2) {
      return _ur ? 'رجحان کے لیے کافی معلومات نہیں' : 'Not enough history to show a trend';
    }
    final fell = assessment.trace.first.percentile - assessment.trace.last.percentile;
    if (fell >= 15) {
      return _ur
          ? 'پچھلے ${assessment.trace.length} دنوں میں مٹی کی نمی تیزی سے کم ہوئی ہے'
          : 'Soil moisture has fallen sharply over the last '
              '${assessment.trace.length} days';
    }
    if (fell <= -5) {
      return _ur
          ? 'مٹی کی نمی بہتر ہو رہی ہے'
          : 'Soil moisture is recovering';
    }
    return _ur ? 'مٹی کی نمی مستحکم ہے' : 'Soil moisture is holding steady';
  }

  @override
  String ringSemantics(RiskAssessment assessment) {
    final percent = (assessment.probability * 100).round();
    final band = bandLabel(assessment.band);
    return _ur
        ? '$band۔ ${assessment.horizonDays} دنوں میں $percent فیصد خطرہ۔ ${rateSummary(assessment)}۔'
        : '$band. $percent percent risk over ${assessment.horizonDays} days. '
            '${rateSummary(assessment)}.';
  }

  @override
  String staleWarning(int ageDays) => _ur
      ? 'یہ معلومات $ageDays دن پرانی ہیں'
      : 'This reading is $ageDays days old';

  @override
  String assessedOn(DateTime date) => DateFormat('d MMM').format(date);

  @override
  String parcelName(String parcelId) => _ur ? 'میرا گندم کا کھیت' : 'My wheat field';

  @override
  String cropAndStage(String parcelId) =>
      _ur ? 'گندم · دانہ بھرنے کا مرحلہ' : 'Wheat · Grain fill';
}
