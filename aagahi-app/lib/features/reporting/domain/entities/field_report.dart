import 'package:equatable/equatable.dart';

/// What the farmer observed in the field (screens_v2.html flow F, F1).
enum ObservationType {
  cropWilting,
  soilCracking,
  cropLoss,
  allFine,
  irrigated,
  rained,
}

/// Where a report stands relative to a future sync pipeline.
///
/// [localOnly] is the only member because there is no outbox or upload path
/// yet (that is later-phase work, explicitly out of scope here) - this is
/// not a speculative enum stubbed out for a future that may not arrive, it
/// is the one real state this phase's reports can be in.
enum SyncState {
  localOnly;

  String get wireValue => switch (this) {
        SyncState.localOnly => 'LOCAL_ONLY',
      };
}

/// A single field observation, captured offline and saved locally
/// (screens_v2.html flow F). [id] is generated on-device (a v4 UUID) so a
/// report can be created, and be a real, addressable thing, before any
/// server has ever seen it.
final class FieldReport extends Equatable {
  const FieldReport({
    required this.id,
    required this.parcelId,
    required this.observationType,
    required this.severity,
    required this.createdAt,
    required this.syncState,
    this.photoPath,
  }) : assert(severity >= 1 && severity <= 5, 'severity must be 1..5');

  final String id;
  final String parcelId;
  final ObservationType observationType;

  /// 1 (mild) .. 5 (worst). A plain bounded int, not an enum - the scale has
  /// no distinct qualitative labels beyond the number itself (screens_v2.html
  /// F2 shows only an emoji and a numeral per step).
  final int severity;

  final DateTime createdAt;
  final SyncState syncState;

  /// Local file path of the attached photo, or null - F4's photo is
  /// explicitly optional.
  final String? photoPath;

  @override
  List<Object?> get props => [
        id,
        parcelId,
        observationType,
        severity,
        createdAt,
        syncState,
        photoPath,
      ];
}
