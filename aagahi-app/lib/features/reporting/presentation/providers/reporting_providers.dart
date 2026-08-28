import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/field_report.dart';
import '../../domain/repositories/field_report_repository.dart';

/// Injected at app start in main.dart, same pattern as
/// `riskRepositoryProvider` - real in both demo and non-demo builds, since
/// field reports have no backend to fake: they are local-only in every
/// build variant this phase.
final fieldReportRepositoryProvider = Provider<FieldReportRepository>(
  (ref) => throw UnimplementedError(
      'Override fieldReportRepositoryProvider at startup'),
);

final savedReportsCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(fieldReportRepositoryProvider).watchSavedCount(),
);

/// Every saved report, newest first - G1 (sync status) lists these as the
/// real content behind "N saved on this phone."
final allFieldReportsProvider = StreamProvider.autoDispose<List<FieldReport>>(
  (ref) => ref.watch(fieldReportRepositoryProvider).watchAll(),
);

/// In-progress answers for the F1-F5 wizard. Nothing here is persisted
/// until F5 calls `FieldReportRepository.save` - this is UI state, not a
/// draft the database knows about.
final class FieldReportDraft {
  const FieldReportDraft({this.observationType, this.severity, this.photoPath});

  final ObservationType? observationType;
  final int? severity;
  final String? photoPath;

  FieldReportDraft copyWith(
          {ObservationType? observationType, int? severity}) =>
      FieldReportDraft(
        observationType: observationType ?? this.observationType,
        severity: severity ?? this.severity,
        photoPath: photoPath,
      );

  FieldReportDraft withPhoto(String? path) => FieldReportDraft(
        observationType: observationType,
        severity: severity,
        photoPath: path,
      );
}

final fieldReportDraftProvider =
    NotifierProvider<FieldReportDraftNotifier, FieldReportDraft>(
  FieldReportDraftNotifier.new,
);

class FieldReportDraftNotifier extends Notifier<FieldReportDraft> {
  @override
  FieldReportDraft build() => const FieldReportDraft();

  void setObservationType(ObservationType type) =>
      state = state.copyWith(observationType: type);

  void setSeverity(int severity) => state = state.copyWith(severity: severity);

  void setPhoto(String? path) => state = state.withPhoto(path);

  void reset() => state = const FieldReportDraft();
}
