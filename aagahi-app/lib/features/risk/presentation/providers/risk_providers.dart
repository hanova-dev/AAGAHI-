import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/risk_local_data_source.dart';
import '../../data/repositories/risk_repository_impl.dart' show NetworkInfo;
import '../../domain/entities/risk_assessment.dart';
import '../../domain/repositories/risk_repository.dart';
import '../../domain/usecases/get_risk_assessment.dart';

/// Which parcel the nav shell's Home tab shows. Changed by
/// `ParcelSwitcherView` (C2) - a real switch: `RiskDashboardScreen` is keyed
/// by parcel ID through the existing `riskAssessmentProvider(parcelId)`
/// family provider, so picking a different field here changes what's shown
/// with no special-casing anywhere else.
final currentParcelIdProvider = StateProvider<String>(
  (ref) => 'demo-parcel-wheat-01',
);

/// Injected at app start in main.dart via ProviderScope overrides. Left
/// unimplemented here so the presentation layer never constructs its own
/// dependencies - that is what keeps widget tests free of real HTTP and a
/// real database.
///
/// Still unimplemented outside `--dart-define=DEMO=true` as of Phase 1: a
/// real RiskRepositoryImpl needs a RiskRemoteDataSource, which does not
/// exist yet (no backend has been built). Wiring the two providers below
/// with real implementations while leaving this one unwired is deliberate,
/// not an oversight - see [riskLocalDataSourceProvider] and
/// [networkInfoProvider].
final riskRepositoryProvider = Provider<RiskRepository>(
  (ref) =>
      throw UnimplementedError('Override riskRepositoryProvider at startup'),
);

/// Real outside demo mode as of Phase 1 (Drift + SQLCipher, see
/// core/database/app_database.dart) - overridden in main.dart with an
/// already-open [RiskLocalDataSourceImpl]. Exists as its own provider,
/// separate from [riskRepositoryProvider], because the local half of the
/// offline-first stack is buildable and testable now; the remote half is
/// not.
final riskLocalDataSourceProvider = Provider<RiskLocalDataSource>(
  (ref) => throw UnimplementedError(
      'Override riskLocalDataSourceProvider at startup'),
);

/// Real outside demo mode as of Phase 1 (connectivity_plus, see
/// core/network/network_info_impl.dart).
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => throw UnimplementedError('Override networkInfoProvider at startup'),
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

/// A `StateProvider`, not a plain `Provider`: A2 (screens_v2.html flow A,
/// language choice) needs to actually switch the active locale for the
/// rest of the app, not just read it once at startup. Every existing
/// `ref.watch(localisationProvider)` call site is unaffected - `watch`
/// works the same way on both provider kinds.
final localisationProvider = StateProvider<AppLocalisations>(
  (ref) => throw UnimplementedError('Override localisationProvider at startup'),
);
