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
    // Generic Failure titles/details (core/error/failures.dart). Every
    // previous live run this session hit these paths only in demo mode
    // (which never surfaces them) or in repository-level tests (which
    // never render them) - a real non-demo run against the unreachable
    // placeholder backend is what first exposed these as missing.
    'failure.network': (
      en: 'No internet connection',
      ur: 'انٹرنیٹ کنکشن نہیں ہے'
    ),
    'failure.network.detail': (
      en: 'We could not reach the server, and nothing is cached yet for '
          'this field.',
      ur: 'ہم سرور تک نہیں پہنچ سکے، اور اس کھیت کے لیے ابھی کچھ محفوظ '
          'شدہ نہیں ہے۔',
    ),
    'failure.server': (
      en: 'Something went wrong on our end',
      ur: 'ہماری طرف کچھ غلط ہوا ہے'
    ),
    'failure.server.detail': (
      en: 'Please try again in a few minutes.',
      ur: 'براہ کرم چند منٹ بعد دوبارہ کوشش کریں۔',
    ),
    'failure.auth': (en: 'You are not signed in', ur: 'آپ سائن ان نہیں ہیں'),
    'failure.auth.detail': (
      en: 'Please sign in again to continue.',
      ur: 'جاری رکھنے کے لیے دوبارہ سائن ان کریں۔',
    ),
    'failure.cache': (
      en: 'Nothing saved on this phone yet',
      ur: 'ابھی اس فون میں کچھ محفوظ نہیں'
    ),
    'failure.cache.detail': (
      en: 'Connect to the internet at least once to load this field.',
      ur: 'اس کھیت کو لوڈ کرنے کے لیے کم از کم ایک بار انٹرنیٹ سے جڑیں۔',
    ),
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
    'parcels.addAnother': (
      en: '+ Add another field',
      ur: '+ ایک اور کھیت شامل کریں'
    ),
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
    'alerts.headline.watchConditions': (
      en: 'Watch conditions',
      ur: 'حالات پر نظر رکھیں'
    ),
    'alerts.headline.conditionsEased': (
      en: 'Conditions eased',
      ur: 'حالات بہتر ہوئے'
    ),
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
    'audio.savedOnThisPhone': (
      en: 'saved on this phone',
      ur: 'اس فون پر محفوظ ہے'
    ),
    'audio.briefingNotDownloaded': (
      en: 'Briefing not downloaded',
      ur: 'بریفنگ ڈاؤن لوڈ نہیں ہوئی',
    ),
    'action.iHaveHeardThis': (
      en: 'I have heard this',
      ur: 'میں نے یہ سن لیا ہے'
    ),
    'action.acknowledged': (en: 'Acknowledged', ur: 'تصدیق ہو گئی'),
    'action.whyIsItDrying': (
      en: 'Why is it drying?',
      ur: 'یہ کیوں خشک ہو رہا ہے؟'
    ),
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
    'action.view14DayTrend': (
      en: 'View 14-day trend',
      ur: '14 دن کا رجحان دیکھیں'
    ),
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
    'advisory.whyNotIrrigation': (
      en: 'Why not irrigation?',
      ur: 'آبپاشی کیوں نہیں؟'
    ),
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
    // Flow F - field reporting (screens_v2.html)
    'action.next': (en: 'Next', ur: 'اگلا'),
    'reporting.localOnlyBanner': (
      en: 'This will be saved on your phone. There is no sync yet.',
      ur: 'یہ آپ کے فون پر محفوظ ہو گا۔ ابھی تک سنک موجود نہیں ہے۔',
    ),
    'reporting.whatDidYouSee': (
      en: 'What did you see in the field?',
      ur: 'آپ نے کھیت میں کیا دیکھا؟',
    ),
    'observation.cropWilting': (en: 'Crop wilting', ur: 'فصل مرجھا رہی ہے'),
    'observation.soilCracking': (en: 'Soil cracking', ur: 'زمین پھٹ رہی ہے'),
    'observation.cropLoss': (en: 'Crop loss', ur: 'نقصان ہوا ہے'),
    'observation.allFine': (en: 'All fine', ur: 'سب ٹھیک ہے'),
    'observation.irrigated': (en: 'I irrigated', ur: 'میں نے پانی دیا'),
    'observation.rained': (en: 'It rained', ur: 'بارش ہوئی'),
    'reporting.howBadIsIt': (en: 'How bad is it?', ur: 'کتنا خراب ہے؟'),
    'reporting.worstSuffix': (en: 'worst', ur: 'بدترین'),
    'reporting.sayWhatYouSee': (
      en: 'Say what you see',
      ur: 'جو دیکھا وہ بتائیں'
    ),
    'reporting.holdToTalkInstructions': (
      en: 'Hold the button. Speak. Let go when you finish.',
      ur: 'بٹن دبائے رکھیں۔ بولیں۔ ختم ہونے پر چھوڑ دیں۔',
    ),
    'voice.notAvailable': (
      en: 'Voice recording is not available in this build.',
      ur: 'اس ورژن میں صوتی ریکارڈنگ دستیاب نہیں ہے۔',
    ),
    'action.skipVoiceNote': (
      en: 'Skip the voice note',
      ur: 'صوتی پیغام چھوڑیں'
    ),
    'reporting.takePicture': (
      en: 'Take a picture (optional)',
      ur: 'تصویر لیں (اختیاری)'
    ),
    'reporting.photoShrunkNote': (
      en: 'The picture is shrunk on your phone before it is saved, to save '
          'your data balance.',
      ur: 'تصویر محفوظ ہونے سے پہلے آپ کے فون پر چھوٹی کر دی جاتی ہے، تاکہ '
          'ڈیٹا بچ سکے۔',
    ),
    'action.gallery': (en: 'Gallery', ur: 'گیلری'),
    'action.capture': (en: 'Capture', ur: 'تصویر لیں'),
    'action.skip': (en: 'Skip', ur: 'چھوڑیں'),
    'reporting.photoPickFailed': (
      en: 'Could not open the camera or gallery.',
      ur: 'کیمرہ یا گیلری نہیں کھل سکی۔',
    ),
    'reporting.reviewTitle': (
      en: 'Save this report?',
      ur: 'کیا یہ رپورٹ محفوظ کریں؟'
    ),
    'action.readItBack': (en: 'Read it back', ur: 'واپس پڑھیں'),
    'reporting.fieldWhat': (en: 'What', ur: 'کیا'),
    'reporting.fieldHowBad': (en: 'How bad', ur: 'کتنا خراب'),
    'reporting.fieldPhoto': (en: 'Photo', ur: 'تصویر'),
    'reporting.onePhoto': (en: '1 image', ur: '1 تصویر'),
    'reporting.noPhoto': (en: 'No photo', ur: 'کوئی تصویر نہیں'),
    'action.saveReport': (en: 'Save report', ur: 'رپورٹ محفوظ کریں'),
    'reporting.saveFailed': (
      en: 'Could not save this report. Please try again.',
      ur: 'یہ رپورٹ محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
    ),
    'reporting.savedOnPhone': (
      en: 'Saved on your phone',
      ur: 'آپ کے فون میں محفوظ ہو گیا'
    ),
    'reporting.savedExplanation': (
      en: 'This report is saved on your phone. There is no sync in this '
          'build yet, so it will stay here until that is built.',
      ur: 'یہ رپورٹ آپ کے فون میں محفوظ ہے۔ اس ورژن میں ابھی سنک موجود نہیں '
          'ہے، اس لیے یہ یہیں رہے گی۔',
    ),
    'reporting.savedCountChip': (
      en: '{count} saved on this phone',
      ur: '{count} اس فون میں محفوظ ہیں',
    ),
    // Flow A - onboarding (screens_v2.html)
    'onboarding.introTitle': (
      en: 'Some droughts arrive in two weeks, not two months',
      ur: 'کچھ خشک سالیاں دو مہینوں میں نہیں، دو ہفتوں میں آ جاتی ہیں',
    ),
    'onboarding.introBody': (
      en: 'Your field can go from healthy to finished before the monthly '
          'bulletin is printed. AAGAHI watches the speed of drying, not '
          'just the amount of rain.',
      ur: 'ماہانہ بلیٹن چھپنے سے پہلے آپ کا کھیت صحت مند سے تباہ ہو سکتا '
          'ہے۔ آگاہی صرف بارش کی مقدار نہیں، خشک ہونے کی رفتار دیکھتی ہے۔',
    ),
    'onboarding.locationTitle': (
      en: 'We need to know where your land is',
      ur: 'ہمیں آپ کی زمین کا محل وقوع جاننا ہے',
    ),
    'onboarding.locationBody': (
      en: 'Only the location of your field, taken once. Not where you are, '
          'not where you go. No officer can see the exact point.',
      ur: 'صرف آپ کے کھیت کا محل وقوع، ایک بار لیا جائے گا۔ نہ یہ کہ آپ '
          'کہاں ہیں، نہ یہ کہ آپ کہاں جاتے ہیں۔ کوئی افسر عین مقام نہیں '
          'دیکھ سکتا۔',
    ),
    'onboarding.locationRefusalBanner': (
      en: 'Refuse and still use the app - you get district warnings '
          'instead of field warnings.',
      ur: 'انکار کریں اور پھر بھی ایپ استعمال کریں - آپ کو کھیت کی بجائے '
          'ضلعی وارننگز ملیں گی۔',
    ),
    'action.allowLocation': (en: 'Allow location', ur: 'مقام کی اجازت دیں'),
    'action.notNow': (en: 'Not now', ur: 'ابھی نہیں'),
    'onboarding.micTitle': (
      en: 'Speak instead of typing',
      ur: 'ٹائپ کرنے کی بجائے بولیں'
    ),
    'onboarding.micBody': (
      en: 'The microphone only records while you hold the button. It never '
          'listens on its own, and field recordings are deleted after '
          'twelve months.',
      ur: 'مائیکروفون صرف اس وقت ریکارڈ کرتا ہے جب آپ بٹن دبائے رکھیں۔ یہ '
          'خود سے کبھی نہیں سنتا، اور ریکارڈنگز بارہ مہینوں بعد حذف ہو '
          'جاتی ہیں۔',
    ),
    'action.allowMicrophone': (
      en: 'Allow microphone',
      ur: 'مائیکروفون کی اجازت دیں'
    ),
    'action.typeInstead': (en: 'Type instead', ur: 'اس کے بجائے ٹائپ کریں'),
    'onboarding.notifTitle': (
      en: 'Warnings reach you even when the app is closed',
      ur: 'ایپ بند ہونے پر بھی وارننگز آپ تک پہنچتی ہیں',
    ),
    'onboarding.notifBody': (
      en: 'At most four messages a week. No advertisements. If there is '
          'nothing to warn you about, we stay quiet.',
      ur: 'ہفتے میں زیادہ سے زیادہ چار پیغامات۔ کوئی اشتہار نہیں۔ اگر '
          'خبردار کرنے کو کچھ نہ ہو تو ہم خاموش رہتے ہیں۔',
    ),
    'onboarding.notifBanner': (
      en: 'No data balance? Warnings also arrive by WhatsApp, SMS, and '
          'voice call.',
      ur: 'ڈیٹا بیلنس نہیں؟ وارننگز واٹس ایپ، ایس ایم ایس، اور کال کے '
          'ذریعے بھی پہنچتی ہیں۔',
    ),
    'action.turnOnWarnings': (en: 'Turn on warnings', ur: 'وارننگز آن کریں'),
    'onboarding.phoneTitle': (
      en: 'Enter your phone number',
      ur: 'اپنا فون نمبر درج کریں'
    ),
    'action.confirmNumber': (en: 'Confirm number', ur: 'نمبر کی تصدیق کریں'),
    'onboarding.otpTitle': (
      en: 'Enter the six-digit code',
      ur: 'چھ ہندسوں کا کوڈ درج کریں'
    ),
    'onboarding.otpSentTo': (en: 'Sent to {phone}', ur: '{phone} پر بھیجا گیا'),
    'onboarding.otpDemoNote': (
      en: 'Any 6 digits work in this demo - there is no SMS backend yet.',
      ur: 'اس ڈیمو میں کوئی بھی 6 ہندسے چلیں گے - ابھی ایس ایم ایس بیک اینڈ '
          'موجود نہیں ہے۔',
    ),
    'action.verify': (en: 'Verify', ur: 'تصدیق کریں'),
    'onboarding.roleTitle': (
      en: 'Who is using this phone?',
      ur: 'یہ فون کون استعمال کر رہا ہے؟'
    ),
    'role.farmer': (en: 'Farmer', ur: 'کاشتکار'),
    'role.officer': (en: 'Extension officer', ur: 'ایکسٹینشن آفیسر'),
    'role.officerSubtitle': (en: 'District dashboard', ur: 'ضلعی ڈیش بورڈ'),
    'role.validator': (en: 'Field validator', ur: 'فیلڈ ویلیڈیٹر'),
    'role.validatorSubtitle': (
      en: 'Confirms reports',
      ur: 'رپورٹس کی تصدیق کرتا ہے'
    ),
    'action.continue': (en: 'Continue', ur: 'جاری رکھیں'),
    // Flow B - parcel registration (screens_v2.html)
    'registration.locationTitle': (
      en: 'Where is this field?',
      ur: 'یہ کھیت کہاں ہے؟'
    ),
    'registration.locationBody': (
      en: 'Rough accuracy is fine. We match you to a nearby area, not a '
          'boundary line.',
      ur: 'اندازاً درستگی کافی ہے۔ ہم آپ کو قریبی علاقے سے ملاتے ہیں، حد '
          'بندی سے نہیں۔',
    ),
    'registration.locationFetching': (
      en: 'Finding your location...',
      ur: 'آپ کا مقام تلاش ہو رہا ہے...'
    ),
    'registration.locationUnavailable': (
      en: 'Location is not available. You can still register this field - '
          'it will get district-level warnings instead of field-level ones.',
      ur: 'مقام دستیاب نہیں ہے۔ آپ پھر بھی یہ کھیت رجسٹر کر سکتے ہیں - اسے '
          'کھیت کی بجائے ضلعی سطح کی وارننگز ملیں گی۔',
    ),
    'registration.locationCaptured': (
      en: 'Location captured',
      ur: 'مقام محفوظ ہو گیا'
    ),
    'action.useThisSpot': (en: 'Use this spot', ur: 'یہ مقام استعمال کریں'),
    'action.continueWithoutLocation': (
      en: 'Continue without location',
      ur: 'مقام کے بغیر جاری رکھیں',
    ),
    'registration.areaTitle': (
      en: 'How big is this field?',
      ur: 'یہ زمین کتنی ہے؟'
    ),
    'registration.areaUnit': (en: 'acres', ur: 'ایکڑ'),
    'action.sayIt': (en: '🎙️ Say it', ur: '🎙️ بولیں'),
    'registration.cropCategoryTitle': (
      en: 'What kind of crop?',
      ur: 'کس قسم کی فصل؟'
    ),
    'category.cereals': (en: 'Cereals & field crops', ur: 'اناج اور بڑی فصلیں'),
    'category.pulsesOilseeds': (
      en: 'Pulses & oilseeds',
      ur: 'دالیں اور تیل کے بیج'
    ),
    'category.vegetables': (en: 'Vegetables', ur: 'سبزیاں'),
    'category.fruits': (en: 'Fruits & orchards', ur: 'پھل اور باغات'),
    'category.fodder': (en: 'Fodder', ur: 'چارہ'),
    'registration.searchCropHint': (
      en: 'Search a crop name',
      ur: 'فصل کا نام تلاش کریں'
    ),
    'registration.noCropMatches': (
      en: 'No crop matches that search.',
      ur: 'اس تلاش سے کوئی فصل نہیں ملی۔',
    ),
    'action.chooseCrop': (en: 'Choose {crop}', ur: '{crop} منتخب کریں'),
    'registration.orchardBanner': (
      en: 'Orchards get a different warning rule - trees survive drying '
          'that would finish a wheat crop.',
      ur: 'باغات کے لیے وارننگ کا اصول مختلف ہے - درخت اس خشکی میں بھی بچ '
          'جاتے ہیں جو گندم کی فصل ختم کر دے۔',
    ),
    'registration.sowingTitle': (en: 'When did you sow?', ur: 'آپ نے کب بویا؟'),
    'registration.sowingBody': (
      en: 'Roughly is enough. This tells us which stage the crop has reached.',
      ur: 'اندازاً کافی ہے۔ اس سے ہمیں پتا چلتا ہے کہ فصل کس مرحلے میں ہے۔',
    ),
    'sowing.thisMonth': (en: 'This month', ur: 'اس مہینے'),
    'sowing.lastMonth': (en: 'Last month', ur: 'پچھلے مہینے'),
    'sowing.twoMonthsAgo': (en: 'Two months ago', ur: 'دو مہینے پہلے'),
    'sowing.pickDate': (en: 'Pick a date', ur: 'تاریخ منتخب کریں'),
    'registration.stageBanner': (
      en: 'Stage now: {stage} - day {day}. You can change this later.',
      ur: 'موجودہ مرحلہ: {stage} - دن {day}۔ آپ اسے بعد میں بدل سکتے ہیں۔',
    ),
    'stage.germination': (en: 'Germination', ur: 'اگاؤ'),
    'stage.vegetative': (en: 'Vegetative', ur: 'نباتاتی نمو'),
    'stage.reproductive': (en: 'Reproductive', ur: 'تولیدی مرحلہ'),
    'stage.maturity': (en: 'Maturity', ur: 'پختگی'),
    'registration.waterTitle': (
      en: 'Where does the water come from?',
      ur: 'پانی کہاں سے آتا ہے؟',
    ),
    'registration.waterBody': (
      en: 'This decides what we can honestly ask you to do.',
      ur: 'یہ طے کرتا ہے کہ ہم آپ سے ایمانداری سے کیا کرنے کو کہہ سکتے ہیں۔',
    ),
    'water.rainOnly': (en: 'Rain only', ur: 'بارانی'),
    'water.canal': (en: 'Canal', ur: 'نہری'),
    'water.tubewell': (en: 'Tubewell', ur: 'ٹیوب ویل'),
    'water.mixed': (en: 'Mixed', ur: 'ملا جلا'),
    'registration.rainFedBanner': (
      en: 'Rain-fed selected - we will never tell you to irrigate. You get '
          'moisture-saving advice instead.',
      ur: 'بارانی منتخب کیا گیا - ہم کبھی آپ کو آبپاشی کرنے کو نہیں کہیں '
          'گے۔ اس کے بجائے نمی بچانے کے مشورے ملیں گے۔',
    ),
    'registration.soilTitle': (
      en: 'What is the soil like?',
      ur: 'مٹی کیسی ہے؟'
    ),
    'registration.soilBody': (
      en: 'Squeeze a damp handful. Which does it behave like?',
      ur: 'ایک نم مٹھی دبائیں۔ یہ کیسا برتاؤ کرتی ہے؟',
    ),
    'soil.sandy': (en: 'Sandy', ur: 'ریتلی'),
    'soil.sandyDesc': (
      en: 'Falls apart - dries fastest',
      ur: 'بکھر جاتی ہے - تیزی سے خشک ہوتی ہے'
    ),
    'soil.loam': (en: 'Loam', ur: 'میرا'),
    'soil.loamDesc': (
      en: 'Holds shape, crumbles',
      ur: 'شکل رکھتی ہے، بھربھری ہوتی ہے'
    ),
    'soil.clay': (en: 'Clay', ur: 'چکنی'),
    'soil.clayDesc': (
      en: 'Sticky - holds water',
      ur: 'چپکنے والی - پانی روکتی ہے'
    ),
    'soil.unknown': (en: 'Not sure', ur: 'یقین نہیں'),
    'soil.unknownDesc': (en: 'We will estimate it', ur: 'ہم اندازہ لگا لیں گے'),
    'registration.confirmTitle': (en: 'Is this right?', ur: 'کیا یہ درست ہے؟'),
    'registration.fieldLabel': (en: 'Field', ur: 'کھیت'),
    'registration.sizeLabel': (en: 'Size', ur: 'رقبہ'),
    'registration.cropLabel': (en: 'Crop', ur: 'فصل'),
    'registration.stageLabel': (en: 'Stage', ur: 'مرحلہ'),
    'registration.waterLabel': (en: 'Water', ur: 'پانی'),
    'registration.soilLabel': (en: 'Soil', ur: 'مٹی'),
    'action.saveThisField': (en: 'Save this field', ur: 'یہ کھیت محفوظ کریں'),
    'action.changeSomething': (en: 'Change something', ur: 'کچھ تبدیل کریں'),
    'registration.saveFailed': (
      en: 'Could not save this field. Please try again.',
      ur: 'یہ کھیت محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    ),
    'parcels.myField': (en: 'My field', ur: 'میرا کھیت'),
    // Crop catalog (screens_v2.html B3a-B3d)
    'crop.wheat': (en: 'Wheat', ur: 'گندم'),
    'crop.rice': (en: 'Rice', ur: 'چاول'),
    'crop.maize': (en: 'Maize', ur: 'مکئی'),
    'crop.cotton': (en: 'Cotton', ur: 'کپاس'),
    'crop.sugarcane': (en: 'Sugarcane', ur: 'گنا'),
    'crop.barley': (en: 'Barley', ur: 'جو'),
    'crop.sorghum': (en: 'Sorghum', ur: 'جوار'),
    'crop.millet': (en: 'Millet', ur: 'باجرہ'),
    'crop.oats': (en: 'Oats', ur: 'جئی'),
    'crop.sugarBeet': (en: 'Sugar beet', ur: 'چقندر'),
    'crop.tobacco': (en: 'Tobacco', ur: 'تمباکو'),
    'crop.other': (en: 'Other', ur: 'دیگر'),
    'crop.chickpea': (en: 'Chickpea', ur: 'چنا'),
    'crop.lentil': (en: 'Lentil', ur: 'مسور'),
    'crop.mung': (en: 'Mung', ur: 'مونگ'),
    'crop.mash': (en: 'Mash', ur: 'ماش'),
    'crop.cowpea': (en: 'Cowpea', ur: 'لوبیا'),
    'crop.mustard': (en: 'Mustard', ur: 'سرسوں'),
    'crop.sunflower': (en: 'Sunflower', ur: 'سورج مکھی'),
    'crop.canola': (en: 'Canola', ur: 'کینولا'),
    'crop.groundnut': (en: 'Groundnut', ur: 'مونگ پھلی'),
    'crop.sesame': (en: 'Sesame', ur: 'تل'),
    'crop.soybean': (en: 'Soybean', ur: 'سویابین'),
    'crop.potato': (en: 'Potato', ur: 'آلو'),
    'crop.onion': (en: 'Onion', ur: 'پیاز'),
    'crop.tomato': (en: 'Tomato', ur: 'ٹماٹر'),
    'crop.chilli': (en: 'Chilli', ur: 'مرچ'),
    'crop.garlic': (en: 'Garlic', ur: 'لہسن'),
    'crop.brinjal': (en: 'Brinjal', ur: 'بینگن'),
    'crop.okra': (en: 'Okra', ur: 'بھنڈی'),
    'crop.spinach': (en: 'Spinach', ur: 'پالک'),
    'crop.cauliflower': (en: 'Cauliflower', ur: 'گوبھی'),
    'crop.cabbage': (en: 'Cabbage', ur: 'بند گوبھی'),
    'crop.carrot': (en: 'Carrot', ur: 'گاجر'),
    'crop.cucumber': (en: 'Cucumber', ur: 'کھیرا'),
    'crop.pumpkin': (en: 'Pumpkin', ur: 'کدو'),
    'crop.turnip': (en: 'Turnip', ur: 'شلجم'),
    'crop.mango': (en: 'Mango', ur: 'آم'),
    'crop.kinnow': (en: 'Kinnow', ur: 'کینو'),
    'crop.guava': (en: 'Guava', ur: 'امرود'),
    'crop.dates': (en: 'Dates', ur: 'کھجور'),
    'crop.banana': (en: 'Banana', ur: 'کیلا'),
    'crop.apple': (en: 'Apple', ur: 'سیب'),
    'crop.grapes': (en: 'Grapes', ur: 'انگور'),
    'crop.peach': (en: 'Peach', ur: 'آڑو'),
    'crop.pomegranate': (en: 'Pomegranate', ur: 'انار'),
    'crop.watermelon': (en: 'Watermelon', ur: 'تربوز'),
    'crop.melon': (en: 'Melon', ur: 'خربوزہ'),
    'crop.olive': (en: 'Olive', ur: 'زیتون'),
    // Flow H - settings (screens_v2.html)
    'settings.title': (en: 'Settings', ur: 'ترتیبات'),
    'settings.notRegisteredYet': (
      en: 'Not registered yet',
      ur: 'ابھی رجسٹرڈ نہیں'
    ),
    'settings.phoneNotSet': (en: 'Phone not set', ur: 'فون نمبر درج نہیں'),
    'settings.languageAndVoice': (
      en: 'Language and voice',
      ur: 'زبان اور آواز'
    ),
    'settings.warningChannels': (
      en: 'How warnings reach me',
      ur: 'وارننگز مجھ تک کیسے پہنچیں'
    ),
    'settings.myFields': (en: 'My fields', ur: 'میرے کھیت'),
    'settings.myFieldsCount': (en: '{count} field', ur: '{count} کھیت'),
    'settings.myFieldsCountZero': (
      en: 'No fields yet',
      ur: 'ابھی کوئی کھیت نہیں'
    ),
    'settings.dataAndPrivacy': (
      en: 'My data and privacy',
      ur: 'میرا ڈیٹا اور رازداری'
    ),
    'settings.sources': (
      en: 'Where our data comes from',
      ur: 'ہمارا ڈیٹا کہاں سے آتا ہے'
    ),
    'settings.cannotDo': (
      en: 'What this app cannot do',
      ur: 'یہ ایپ کیا نہیں کر سکتی'
    ),
    'settings.syncStatus': (en: 'Sync status', ur: 'سنک کی صورتحال'),
    'settings.autoplayOn': (en: 'autoplay on', ur: 'خودکار چلنا آن ہے'),
    'settings.autoplayOff': (en: 'autoplay off', ur: 'خودکار چلنا آف ہے'),
    'settings.whatsappFirst': (en: 'WhatsApp first', ur: 'پہلے واٹس ایپ'),
    'settings.quietRange': (
      en: 'quiet {start}-{end}',
      ur: 'خاموشی {start}-{end}'
    ),
    // H2 - language and voice
    'settings.languageSection': (en: 'LANGUAGE', ur: 'زبان'),
    'settings.voiceSection': (en: 'VOICE', ur: 'آواز'),
    'settings.readScreensAloud': (
      en: 'Read screens aloud',
      ur: 'اسکرینیں پڑھ کر سنائیں'
    ),
    'settings.readScreensAloudSubtitle': (
      en: 'Starts automatically',
      ur: 'خودکار طور پر شروع ہوتا ہے',
    ),
    'settings.slowerSpeech': (en: 'Slower speech', ur: 'آہستہ بولنا'),
    'settings.slowerSpeechSubtitle': (
      en: 'For clearer listening',
      ur: 'واضح سننے کے لیے'
    ),
    'settings.biggerText': (en: 'Bigger text', ur: 'بڑا حروف'),
    'settings.biggerTextSubtitle': (
      en: '200% size supported',
      ur: '200% سائز معاون ہے'
    ),
    'action.hearSample': (en: 'Hear a sample', ur: 'نمونہ سنیں'),
    // H3 - warning channels & quiet hours
    'settings.channelsIntro': (
      en: 'We try these in order until one works.',
      ur: 'ہم انہیں ترتیب سے آزماتے ہیں جب تک ایک کام نہ کرے۔',
    ),
    'settings.channel.whatsapp': (en: 'WhatsApp', ur: 'واٹس ایپ'),
    'settings.channel.appNotification': (
      en: 'App notification',
      ur: 'ایپ اطلاع'
    ),
    'settings.channel.sms': (en: 'SMS', ur: 'ایس ایم ایس'),
    'settings.channel.voiceCall': (en: 'Voice call', ur: 'صوتی کال'),
    'settings.quietHours': (en: 'QUIET HOURS', ur: 'خاموشی کے اوقات'),
    'settings.noMessagesBetween': (
      en: 'No messages between',
      ur: 'ان اوقات میں کوئی پیغام نہیں'
    ),
    'settings.maxWarningsBanner': (
      en: 'Never more than 4 warnings a week.',
      ur: 'ہفتے میں کبھی بھی 4 سے زیادہ وارننگز نہیں۔',
    ),
    // H4 - data & privacy
    'settings.whatWeKeep': (en: 'What we keep', ur: 'ہم کیا رکھتے ہیں'),
    'settings.whatWeKeepBody': (
      en: 'Your number, your fields, and the reports you send. Nothing '
          'else. We never look at your contacts or your other apps.',
      ur: 'آپ کا نمبر، آپ کے کھیت، اور آپ کی بھیجی گئی رپورٹس۔ اور کچھ '
          'نہیں۔ ہم کبھی آپ کے رابطے یا دیگر ایپس نہیں دیکھتے۔',
    ),
    'settings.whoCanSeeLocation': (
      en: 'Who can see your field location',
      ur: 'آپ کے کھیت کا مقام کون دیکھ سکتا ہے',
    ),
    'settings.whoCanSeeLocationBody': (
      en: 'Only you. Officers see district totals, never your exact point.',
      ur: 'صرف آپ۔ افسران ضلعی کل تعداد دیکھتے ہیں، کبھی آپ کا عین مقام نہیں۔',
    ),
    'settings.downloadMyData': (
      en: 'Download my data',
      ur: 'میرا ڈیٹا ڈاؤن لوڈ کریں'
    ),
    'settings.readPrivacyNotice': (
      en: 'Read the privacy notice',
      ur: 'رازداری کا نوٹس پڑھیں',
    ),
    'settings.readPrivacyNoticeSubtitle': (
      en: 'Urdu · also as audio',
      ur: 'اردو · آواز میں بھی'
    ),
    'settings.deleteAccount': (
      en: 'Delete my account',
      ur: 'میرا اکاؤنٹ حذف کریں'
    ),
    'settings.deleteAccountSubtitle': (
      en: 'Erases everything saved on this phone',
      ur: 'اس فون میں محفوظ ہر چیز مٹا دیتا ہے',
    ),
    'settings.neverSellData': (
      en: 'We never sell your data. Not to anyone.',
      ur: 'ہم آپ کا ڈیٹا کبھی نہیں بیچتے۔ کسی کو بھی نہیں۔',
    ),
    'settings.notAvailableYet': (
      en: 'Not available in this build yet.',
      ur: 'یہ ابھی اس ورژن میں دستیاب نہیں ہے۔',
    ),
    'settings.deleteConfirmTitle': (
      en: 'Delete everything on this phone?',
      ur: 'اس فون سے سب کچھ حذف کریں؟'
    ),
    'settings.deleteConfirmBody': (
      en: 'This erases your field, your reports, and your settings from '
          'this phone. This cannot be undone.',
      ur: 'یہ آپ کا کھیت، آپ کی رپورٹس، اور آپ کی ترتیبات اس فون سے مٹا '
          'دے گا۔ اسے واپس نہیں لایا جا سکتا۔',
    ),
    'action.deleteForever': (en: 'Delete everything', ur: 'سب کچھ حذف کریں'),
    'action.cancel': (en: 'Cancel', ur: 'منسوخ کریں'),
    // H5 - sources & licences
    'settings.source.smap': (en: 'NASA SMAP', ur: 'ناسا SMAP'),
    'settings.source.smapDesc': (
      en: 'Soil moisture · public domain',
      ur: 'مٹی کی نمی · عوامی ڈومین'
    ),
    'settings.source.era5': (
      en: 'ERA5-Land · Copernicus',
      ur: 'ERA5-Land · کوپرنیکس'
    ),
    'settings.source.era5Desc': (
      en: 'Temperature and humidity',
      ur: 'درجہ حرارت اور نمی'
    ),
    'settings.source.tropomi': (
      en: 'Sentinel-5P TROPOMI',
      ur: 'Sentinel-5P TROPOMI'
    ),
    'settings.source.tropomiDesc': (
      en: 'Plant stress signal (SIF)',
      ur: 'پودوں کے دباؤ کا اشارہ (SIF)',
    ),
    'settings.source.chirps': (en: 'CHIRPS', ur: 'CHIRPS'),
    'settings.source.chirpsDesc': (
      en: 'Rainfall · UCSB/USGS',
      ur: 'بارش · UCSB/USGS'
    ),
    'settings.source.modis': (en: 'MODIS', ur: 'MODIS'),
    'settings.source.modisDesc': (
      en: 'Greenness · fallback only',
      ur: 'ہریالی · صرف متبادل کے طور پر'
    ),
    'settings.openSourceCredits': (
      en: 'Open-source: Flutter (BSD-3), LightGBM (MIT), SHAP (MIT), '
          'Noto Nastaliq Urdu (OFL 1.1).',
      ur: 'اوپن سورس: Flutter (BSD-3)، LightGBM (MIT)، SHAP (MIT)، Noto '
          'Nastaliq Urdu (OFL 1.1)۔',
    ),
    // H6 - what this app cannot do
    'settings.cannotDo.rain': (
      en: 'It cannot tell you whether it will rain.',
      ur: 'یہ نہیں بتا سکتی کہ بارش ہو گی یا نہیں۔',
    ),
    'settings.cannotDo.cropFate': (
      en: 'It cannot promise your crop will fail, or that it will survive.',
      ur: 'یہ ضمانت نہیں دے سکتی کہ آپ کی فصل خراب ہو گی یا بچ جائے گی۔',
    ),
    'settings.cannotDo.replaceDept': (
      en: 'It does not replace the Agriculture Department. Follow their '
          'advice too.',
      ur: 'یہ محکمہ زراعت کا متبادل نہیں ہے۔ ان کے مشورے پر بھی عمل کریں۔',
    ),
    'settings.cannotDo.wrongBefore': (
      en: 'It is sometimes wrong. It has missed real droughts and raised '
          'false alarms.',
      ur: 'یہ کبھی کبھار غلط ہوتی ہے۔ اس نے حقیقی خشک سالیاں چھوڑی ہیں اور '
          'جھوٹے الارم بھی دیے ہیں۔',
    ),
    'settings.cannotDo.silentWhenBlind': (
      en: 'It says nothing when the satellites give us nothing.',
      ur: 'جب سیٹلائٹ کچھ نہیں دیتے تو یہ بھی کچھ نہیں کہتی۔',
    ),
    'settings.performanceTitle': (
      en: 'How well it has done so far',
      ur: 'اب تک اس کی کارکردگی کیسی رہی',
    ),
    'settings.performanceCaught': (
      en: 'Caught 7 of 10 real drying events',
      ur: '10 میں سے 7 حقیقی خشکی کے واقعات پکڑے',
    ),
    'settings.performanceFalseAlarm': (
      en: '3 of every 10 warnings were false alarms. Measured on 2024-2025 '
          'data in this district.',
      ur: 'ہر 10 وارننگز میں سے 3 جھوٹے الارم تھے۔ اس ضلعے کے 2024-2025 '
          'کے ڈیٹا پر ماپا گیا۔',
    ),
    'settings.versionFooter': (
      en: 'Version 1.0 · model v2026.08',
      ur: 'ورژن 1.0 · ماڈل v2026.08'
    ),
    // Flow G - sync & conflicts
    'sync.title': (en: 'Sync status', ur: 'سنک کی صورتحال'),
    'sync.localOnlySummary': (
      en: '{count} saved on this phone',
      ur: '{count} اس فون میں محفوظ ہیں',
    ),
    'sync.allLocalNote': (
      en: 'There is no sync yet - everything stays on this phone until '
          'that is built.',
      ur: 'ابھی سنک موجود نہیں - جب تک یہ نہ بن جائے سب کچھ اس فون میں '
          'رہے گا۔',
    ),
    'sync.savedOnPhone': (en: 'Saved on this phone', ur: 'اس فون میں محفوظ'),
    'sync.neverAutoDeleted': (
      en: 'Reports are never deleted automatically.',
      ur: 'رپورٹس کبھی خودکار طور پر حذف نہیں ہوتیں۔',
    ),
    'sync.seeConflictDemo': (
      en: 'See how conflicts will be resolved',
      ur: 'دیکھیں تنازعات کیسے حل ہوں گے',
    ),
    'sync.noReportsYet': (
      en: 'No field reports saved yet.',
      ur: 'ابھی کوئی فیلڈ رپورٹ محفوظ نہیں۔'
    ),
    'sync.conflictBanner': (
      en: 'Two different versions of this field exist.',
      ur: 'اس کھیت کے دو مختلف ورژن موجود ہیں۔',
    ),
    'sync.conflictTitle': (en: 'Which one is correct?', ur: 'کون سا درست ہے؟'),
    'sync.conflictBody': (
      en: 'You changed this on your phone. Someone also changed it '
          'elsewhere.',
      ur: 'آپ نے اسے اپنے فون پر تبدیل کیا۔ کسی نے اسے کہیں اور بھی تبدیل کیا۔',
    ),
    'sync.onThisPhone': (en: 'On this phone', ur: 'اس فون پر'),
    'sync.onTheServer': (en: 'On the server', ur: 'سرور پر'),
    'sync.seededNote': (
      en: 'This is a seeded example - there is no real conflict source yet.',
      ur: 'یہ ایک نمونہ مثال ہے - ابھی کوئی حقیقی تنازعہ کا ذریعہ نہیں ہے۔',
    ),
    'action.keepMyPhoneVersion': (
      en: "Keep my phone's version",
      ur: 'میرے فون کا ورژن رکھیں'
    ),
    'action.keepServerVersion': (
      en: 'Keep the server version',
      ur: 'سرور کا ورژن رکھیں'
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
  String get whyIsItDrying =>
      _ur ? 'یہ کیوں خشک ہو رہا ہے' : 'Why is it drying';

  @override
  String get howSureAreWe => _ur ? 'ہمیں کتنا یقین ہے' : 'How sure are we';

  @override
  String get tryAgain => _ur ? 'دوبارہ کوشش کریں' : 'Try again';

  @override
  String get degradedInputsNote => _ur
      ? 'کچھ اعداد و شمار کا تخمینہ لگایا گیا ہے'
      : 'Some readings were estimated';

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
  String horizonCaption(int days) =>
      _ur ? '$days دن کا خطرہ' : '$days-DAY RISK';

  @override
  String rateSummary(RiskAssessment assessment) {
    if (assessment.trace.length < 2) {
      return _ur
          ? 'رجحان کے لیے کافی معلومات نہیں'
          : 'Not enough history to show a trend';
    }
    final fell =
        assessment.trace.first.percentile - assessment.trace.last.percentile;
    if (fell >= 15) {
      return _ur
          ? 'پچھلے ${assessment.trace.length} دنوں میں مٹی کی نمی تیزی سے کم ہوئی ہے'
          : 'Soil moisture has fallen sharply over the last '
              '${assessment.trace.length} days';
    }
    if (fell <= -5) {
      return _ur ? 'مٹی کی نمی بہتر ہو رہی ہے' : 'Soil moisture is recovering';
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
    'demo-parcel-wheat-01': (
      en: 'Wheat · Grain fill',
      ur: 'گندم · دانہ بھرنے کا مرحلہ'
    ),
    'demo-parcel-mustard-02': (en: 'Mustard · day 61', ur: 'سرسوں · دن 61'),
    'demo-parcel-maize-03': (en: 'Maize · day 12', ur: 'مکئی · دن 12'),
    'demo-parcel-mango-04': (en: 'Mango orchard', ur: 'آم کا باغ'),
  };

  @override
  String parcelName(String parcelId) => _parcelNames[parcelId] ?? 'Chak 42/GB';

  @override
  String cropAndStage(String parcelId) {
    final entry =
        _cropAndStage[parcelId] ?? _cropAndStage['demo-parcel-wheat-01']!;
    return _ur ? entry.ur : entry.en;
  }
}
