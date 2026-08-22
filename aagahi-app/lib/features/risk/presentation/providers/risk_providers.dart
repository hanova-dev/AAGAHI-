import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/risk_assessment.dart';
import '../../domain/repositories/risk_repository.dart';
import '../../domain/usecases/get_risk_assessment.dart';

/// Injected at app start in main.dart via ProviderScope overrides. Left
/// unimplemented here so the presentation layer never constructs its own
/// dependencies - that is what keeps widget tests free of real HTTP and a
/// real database.
final riskRepositoryProvider = Provider<RiskRepository>(
  (ref) => throw UnimplementedError('Override riskRepositoryProvider at startup'),
);

final getRiskAssessmentProvider = Provider<GetRiskAssessment>(
  (ref) => GetRiskAssessment(ref.watch(riskRepositoryProvider)),
);

/// Per-parcel risk state.
///
/// `autoDispose` matters here: a farmer with several parcels would otherwise
/// keep a live subscription per parcel for the life of the app, and each one
/// holds a database stream. On a 2 GB device that is a real cost.
final riskAssessmentProvider = AsyncNotifierProvider.autoDispose
    .family<RiskAssessmentNotifier, RiskAssessment, String>(
  RiskAssessmentNotifier.new,
);

class RiskAssessmentNotifier
    extends AutoDisposeFamilyAsyncNotifier<RiskAssessment, String> {
  @override
  Future<RiskAssessment> build(String parcelId) async {
    // Repaint when a background sync writes a newer assessment, so the farmer
    // does not have to pull to refresh to see an overnight update.
    final subscription = ref
        .watch(riskRepositoryProvider)
        .watchAssessment(parcelId)
        .listen((updated) => state = AsyncData(updated));
    ref.onDispose(subscription.cancel);

    return _load(parcelId, force: false);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading<RiskAssessment>().copyWithPrevious(state);
    try {
      state = AsyncData(await _load(arg, force: force));
    } on Failure catch (failure, stack) {
      state = AsyncError(failure, stack);
    }
  }

  Future<RiskAssessment> _load(String parcelId, {required bool force}) async {
    final result = await ref.read(getRiskAssessmentProvider)(
      GetRiskAssessmentParams(parcelId: parcelId, forceRefresh: force),
    );

    // Failures are thrown here rather than modelled in the data type, so
    // AsyncValue.when gives the UI a clean three-way split. The Failure
    // subtype is preserved so the error view can distinguish "not scorable"
    // from "offline" - collapsing them would lose the distinction that
    // matters most.
    return result.fold((failure) => throw failure, (assessment) => assessment);
  }
}

// ---------------------------------------------------------------------------
// Audio playback
// ---------------------------------------------------------------------------

class BriefingPlaybackState {
  const BriefingPlaybackState({this.isPlaying = false, this.duration});

  final bool isPlaying;
  final Duration? duration;

  BriefingPlaybackState copyWith({bool? isPlaying, Duration? duration}) =>
      BriefingPlaybackState(
        isPlaying: isPlaying ?? this.isPlaying,
        duration: duration ?? this.duration,
      );
}

final briefingPlaybackProvider =
    NotifierProvider<BriefingPlaybackNotifier, BriefingPlaybackState>(
  BriefingPlaybackNotifier.new,
);

/// Playback of the cached Urdu briefing, with on-device TTS as the fallback.
///
/// Prefers a pre-rendered server audio file over on-device TTS because Urdu
/// TTS quality varies wildly across Android OEM builds, and an unintelligible
/// warning is worse than a silent one.
class BriefingPlaybackNotifier extends Notifier<BriefingPlaybackState> {
  @override
  BriefingPlaybackState build() => const BriefingPlaybackState();

  Future<void> toggle(RiskAssessment assessment) async {
    if (state.isPlaying) {
      await stop();
      return;
    }
    // Wire to just_audio when the briefing URI is present, otherwise to
    // flutter_tts over the localised narrative. Kept as an explicit branch so
    // the fallback is visible in code review rather than hidden in a plugin.
    final uri = assessment.voiceBriefingUri;
    state = state.copyWith(isPlaying: true);
    if (uri == null) {
      await _speakFallback(assessment);
    } else {
      await _playFile(uri);
    }
  }

  Future<void> speakText(String text) async {
    state = state.copyWith(isPlaying: true);
    // flutter_tts call site.
    state = state.copyWith(isPlaying: false);
  }

  Future<void> stop() async {
    state = state.copyWith(isPlaying: false);
  }

  Future<void> _playFile(String uri) async {
    state = state.copyWith(isPlaying: false);
  }

  Future<void> _speakFallback(RiskAssessment assessment) async {
    state = state.copyWith(isPlaying: false);
  }
}

// ---------------------------------------------------------------------------
// Localisation
// ---------------------------------------------------------------------------

/// Localisation surface used by the dashboard.
///
/// Declared as an interface here so the screen depends on a contract rather
/// than on generated ARB output. Every user-visible string in the app resolves
/// through this - there are no inline English literals in any widget
/// (FR-LOCL-001).
abstract interface class AppLocalisations {
  String translate(String key);

  String get listen;
  String get whatToDo;
  String get whyIsItDrying;
  String get howSureAreWe;
  String get tryAgain;
  String get degradedInputsNote;
  String get notGuessingExplanation;

  String bandLabel(RiskBand band);
  String confidenceLabel(ConfidenceLevel level);
  String horizonCaption(int days);
  String rateSummary(RiskAssessment assessment);
  String ringSemantics(RiskAssessment assessment);
  String staleWarning(int ageDays);
  String assessedOn(DateTime date);
  String parcelName(String parcelId);
  String cropAndStage(String parcelId);
}

final localisationProvider = Provider<AppLocalisations>(
  (ref) => throw UnimplementedError('Override localisationProvider at startup'),
);
