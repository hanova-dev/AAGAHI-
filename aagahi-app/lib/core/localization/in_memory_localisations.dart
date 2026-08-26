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
    // D1 - footnote shown only under the top-ranked driver card, and only
    // when that driver is evaporative demand - exact copy from
    // screens_v2.html flow D, paired with the one driver it actually
    // describes ("the air itself is thirsty").
    'driver.evaporativeDemand.footnote': (
      en: 'This is not about rain. The air itself is thirsty.',
      ur: 'یہ بارش کے بارے میں نہیں ہے۔ ہوا خود پیاسی ہے۔',
    ),
    'advisory.irrigateNow': (
      en: 'Irrigate now if you can',
      ur: 'اگر ممکن ہو تو ابھی پانی دیں',
    ),
    // C3 - not scorable (screens_v2.html flow C)
    'failure.notScorable': (
      en: 'We cannot tell you today',
      ur: 'آج ہم آپ کو نہیں بتا سکتے',
    ),
    'notScorable.insufficientCoverage': (
      en: 'The satellite that measures soil moisture has not sent usable '
          'data for your area in four days. Clouds are the usual reason.',
      ur: 'آپ کے علاقے کے لیے مٹی کی نمی ناپنے والا سیٹلائٹ چار دن سے '
          'قابلِ استعمال ڈیٹا نہیں بھیج رہا۔ عام طور پر بادل اس کی وجہ ہوتے ہیں۔',
    ),
    'action.seeDistrictWarning': (
      en: 'See district warning instead',
      ur: 'اس کے بجائے ضلعی وارننگ دیکھیں',
    ),
    // C2 - parcel switcher
    'parcels.yourFields': (en: 'Your fields', ur: 'آپ کے کھیت'),
    'parcels.addAnother': (en: '+ Add another field', ur: '+ ایک اور کھیت شامل کریں'),
    // Nav shell
    'nav.home': (en: 'Home', ur: 'گھر'),
    'nav.warnings': (en: 'Warnings', ur: 'وارننگز'),
    'nav.report': (en: 'Report', ur: 'رپورٹ'),
    'nav.settings': (en: 'Settings', ur: 'ترتیبات'),
    // E1 - alert list
    'alerts.newSuffix': (en: 'new', ur: 'نئی'),
    'alerts.monthlySummary': (
      en: 'You have had {count} warnings this month.',
      ur: 'اس مہینے آپ کو {count} وارننگز موصول ہوئیں۔',
    ),
    'alerts.status.heard': (en: 'heard', ur: 'سنا گیا'),
    'alerts.status.repliedByYou': (en: 'you replied', ur: 'آپ نے جواب دیا'),
    'alerts.status.voiceSeconds': (
      en: '{seconds} sec voice',
      ur: '{seconds} سیکنڈ کی آواز',
    ),
    'alerts.channel.push': (en: 'Push', ur: 'پش'),
    'alerts.channel.whatsapp': (en: 'WhatsApp', ur: 'واٹس ایپ'),
    'alerts.channel.sms': (en: 'SMS', ur: 'ایس ایم ایس'),
    'alerts.headline.rapidDrying': (
      en: 'Rapid drying expected',
      ur: 'تیزی سے خشکی متوقع ہے',
    ),
    'alerts.headline.watchConditions': (en: 'Watch conditions', ur: 'حالات پر نظر رکھیں'),
    'alerts.headline.conditionsEased': (en: 'Conditions eased', ur: 'حالات بہتر ہوئے'),
    'alerts.headline.severeDrying': (en: 'Severe drying', ur: 'شدید خشکی'),
    // E2 - alert detail
    'alerts.detail.dangerHeadline': (
      en: 'The next ten days are dangerous for this field',
      ur: 'اگلے دس دن اس کھیت کے لیے خطرناک ہیں',
    ),
    'alerts.detail.doThisWeek': (en: 'Do this week', ur: 'اس ہفتے یہ کریں'),
    'alerts.advice.cutWeeds': (
      en: 'Cut weeds and mulch the rows',
      ur: 'جڑی بوٹیاں کاٹیں اور قطاروں پر ملچ کریں',
    ),
    'alerts.advice.keepMonitoring': (
      en: 'Keep monitoring soil moisture',
      ur: 'مٹی کی نمی پر نظر رکھیں',
    ),
    'alerts.advice.noActionNeeded': (
      en: 'No action needed - conditions are fine',
      ur: 'کوئی کارروائی درکار نہیں - حالات ٹھیک ہیں',
    ),
    'audio.urduVoiceMessage': (en: 'Urdu voice message', ur: 'اردو صوتی پیغام'),
    'audio.savedOnThisPhone': (en: 'saved on this phone', ur: 'اس فون پر محفوظ ہے'),
    'audio.briefingNotDownloaded': (
      en: 'Briefing not downloaded',
      ur: 'بریفنگ ڈاؤن لوڈ نہیں ہوئی',
    ),
    'action.iHaveHeardThis': (en: 'I have heard this', ur: 'میں نے یہ سن لیا ہے'),
    'action.acknowledged': (en: 'Acknowledged', ur: 'تصدیق ہو گئی'),
    'action.whyIsItDrying': (en: 'Why is it drying?', ur: 'یہ کیوں خشک ہو رہا ہے؟'),
    // D1 - causal explanation (screens_v2.html flow D)
    'driverRank.biggest': (en: 'Biggest cause', ur: 'سب سے بڑی وجہ'),
    'driverRank.second': (en: 'Second cause', ur: 'دوسری وجہ'),
    'driverRank.third': (en: 'Third cause', ur: 'تیسری وجہ'),
    'causal.closingBanner': (
      en: 'Rainfall alone would not have warned you. The speed of drying is '
          'what raised this.',
      ur: 'صرف بارش کی کمی آپ کو خبردار نہ کرتی۔ خشک ہونے کی رفتار نے یہ '
          'وارننگ جاری کروائی ہے۔',
    ),
    'action.view14DayTrend': (en: 'View 14-day trend', ur: '14 دن کا رجحان دیکھیں'),
    // D2 - 14-day trace (screens_v2.html flow D)
    'trace.title': (en: 'Last 14 days', ur: 'پچھلے 14 دن'),
    'trace.soilMoisturePercentile': (
      en: 'Soil moisture percentile',
      ur: 'مٹی کی نمی کا فیصد درجہ',
    ),
    'trace.fiveDayFall': (en: '5-day fall', ur: '5 دن میں کمی'),
    'trace.fourteenDayFall': (en: '14-day fall', ur: '14 دن میں کمی'),
    'trace.rapidDryingBanner': (
      en: 'A fall of 20 points or more inside two weeks is what we call '
          'rapid drying.',
      ur: 'دو ہفتوں میں 20 یا زیادہ پوائنٹس کی کمی کو ہم تیز خشکی کہتے ہیں۔',
    ),
    // D3 - what to do (screens_v2.html flow D)
    'advisory.cutWeedsAndMulch': (
      en: 'Cut the weeds and cover the rows',
      ur: 'جڑی بوٹیاں کاٹیں اور قطاروں کو ڈھانپیں',
    ),
    'advisory.cutWeedsAndMulch.body': (
      en: 'Weeds drink the same water as your wheat. Removing them and '
          'laying stubble over the soil slows the loss you are seeing.',
      ur: 'جڑی بوٹیاں بھی وہی پانی پیتی ہیں جو آپ کی گندم پیتی ہے۔ انہیں '
          'ہٹانے اور مٹی پر بھوسا بچھانے سے یہ نمی کا نقصان سست ہو جاتا ہے۔',
    ),
    'advisory.whyNotIrrigation': (en: 'Why not irrigation?', ur: 'آبپاشی کیوں نہیں؟'),
    'advisory.whyNotIrrigation.body': (
      en: 'You told us this field is rain-fed. We will not ask you to do '
          'something you have no water for.',
      ur: 'آپ نے بتایا تھا کہ یہ کھیت بارانی ہے۔ ہم آپ سے وہ کام کرنے کو '
          'نہیں کہیں گے جس کے لیے آپ کے پاس پانی نہیں ہے۔',
    ),
    'action.iHaveDoneThis': (en: 'I have done this', ur: 'میں نے یہ کر لیا ہے'),
    'action.done': (en: 'Done', ur: 'ہو گیا'),
    // D4 - how sure are we (screens_v2.html flow D)
    'confidence.title': (
      en: "Confidence in today's warning",
      ur: 'آج کی وارننگ پر ہمارا یقین',
    ),
    'confidence.explanationDegraded': (
      en: "Some of today's measurements were estimated because of cloud "
          'cover or a missed satellite pass.',
      ur: 'آج کی کچھ پیمائشیں بادلوں یا سیٹلائٹ کے نہ گزرنے کی وجہ سے '
          'تخمینہ لگا کر حاصل کی گئیں۔',
    ),
    'confidence.explanationComplete': (
      en: 'All the measurements this warning needed were available today.',
      ur: 'اس وارننگ کے لیے درکار تمام پیمائشیں آج دستیاب تھیں۔',
    ),
    'confidence.cannotDoTitle': (
      en: 'What this warning cannot do',
      ur: 'یہ وارننگ کیا نہیں کر سکتی',
    ),
    'confidence.cannotDo.rain': (
      en: 'It cannot tell you if it will rain',
      ur: 'یہ نہیں بتا سکتی کہ بارش ہو گی یا نہیں',
    ),
    'confidence.cannotDo.cropFailure': (
      en: 'It cannot promise your crop will fail',
      ur: 'یہ یہ ضمانت نہیں دے سکتی کہ آپ کی فصل خراب ہو جائے گی',
    ),
    'confidence.cannotDo.wrongBefore': (
      en: 'It has been wrong before and will be wrong again',
      ur: 'یہ پہلے بھی غلط ثابت ہوئی ہے اور آئندہ بھی ہو سکتی ہے',
    ),
    'confidence.districtAdvisoryBanner': (
      en: 'Also check the district advisory from the Agriculture Department '
          'before a costly decision.',
      ur: 'کوئی مہنگا فیصلہ کرنے سے پہلے محکمہ زراعت کی ضلعی ایڈوائزری بھی '
          'ضرور دیکھیں۔',
    ),
    // C4 - offline / stale (screens_v2.html flow C)
    'offline.noInternetTitle': (en: 'No internet.', ur: 'انٹرنیٹ نہیں ہے۔'),
    'offline.noInternetBody': (
      en: 'Showing what we last received.',
      ur: 'ہم نے آخری بار جو معلومات وصول کیں وہ دکھا رہے ہیں۔',
    ),
    'offline.staleWarningBanner': (
      en: 'Conditions may have changed since this reading. Connect when you can.',
      ur: 'اس ریڈنگ کے بعد حالات بدل چکے ہوں گے۔ جب ممکن ہو انٹرنیٹ سے جڑیں۔',
    ),
    'common.daysOld': (en: 'days old', ur: 'دن پرانا'),
    'common.asOf': (en: 'AS OF', ur: 'بمطابق'),
    'common.saved': (en: 'saved', ur: 'محفوظ شدہ'),
    'action.tryToConnect': (en: 'Try to connect', ur: 'جڑنے کی کوشش کریں'),
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

  // Exact copy from screens_v2.html C3, not paraphrased - this sentence is
  // the product's ethical position stated to the user, verbatim.
  @override
  String get notGuessingExplanation => _ur
      ? 'ہم آپ کو کم خطرہ نہیں دکھا رہے۔ ہم کچھ نہیں دکھا رہے، کیونکہ ہم صرف اندازہ لگا رہے ہوں گے۔'
      : 'We are not showing you a low score. We are showing you nothing, '
          'because we would be guessing.';

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

  // Parcel names are proper nouns (place names, same as "Chak 42/GB"
  // elsewhere in this app) - not translated between locales. Crop/stage
  // text does vary by locale. Keyed by the four seeded demo parcel IDs
  // (see demo/demo_risk_repository.dart's DemoParcelSummary list); an
  // unrecognised ID falls back to the original single-parcel copy rather
  // than throwing, consistent with this class never crashing on
  // unrecognised input.
  static const _parcelNames = <String, String>{
    'demo-parcel-wheat-01': 'Chak 42/GB',
    'demo-parcel-mustard-02': 'Kotli plot',
    'demo-parcel-maize-03': 'Nehri rakba',
    'demo-parcel-mango-04': 'Bagh',
  };

  static const _cropAndStage = <String, ({String en, String ur})>{
    'demo-parcel-wheat-01': (en: 'Wheat · Grain fill', ur: 'گندم · دانہ بھرنے کا مرحلہ'),
    'demo-parcel-mustard-02': (en: 'Mustard · day 61', ur: 'سرسوں · دن 61'),
    'demo-parcel-maize-03': (en: 'Maize · day 12', ur: 'مکئی · دن 12'),
    'demo-parcel-mango-04': (en: 'Mango orchard', ur: 'آم کا باغ'),
  };

  @override
  String parcelName(String parcelId) => _parcelNames[parcelId] ?? 'Chak 42/GB';

  @override
  String cropAndStage(String parcelId) {
    final entry = _cropAndStage[parcelId] ??
        _cropAndStage['demo-parcel-wheat-01']!;
    return _ur ? entry.ur : entry.en;
  }
}
