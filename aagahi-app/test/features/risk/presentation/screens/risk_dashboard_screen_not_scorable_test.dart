import 'package:aagahi/core/error/failures.dart';
import 'package:aagahi/core/localization/in_memory_localisations.dart';
import 'package:aagahi/features/risk/domain/entities/risk_assessment.dart';
import 'package:aagahi/features/risk/domain/repositories/risk_repository.dart';
import 'package:aagahi/features/risk/presentation/providers/risk_providers.dart';
import 'package:aagahi/features/risk/presentation/screens/not_scorable_view.dart';
import 'package:aagahi/features/risk/presentation/screens/risk_dashboard_screen.dart';
import 'package:aagahi/shared_widgets/risk_ring.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A repository that always reports the cell as not scorable - the one
/// behaviour this test exists to pin down.
class _NotScorableRepository implements RiskRepository {
  const _NotScorableRepository();

  @override
  Future<Either<Failure, RiskAssessment>> getLatestAssessment({
    required String parcelId,
    bool forceRefresh = false,
  }) async {
    return const Left(
      NotScorableFailure(reasonKey: 'notScorable.insufficientCoverage'),
    );
  }

  @override
  Stream<RiskAssessment> watchAssessment(String parcelId) => const Stream.empty();

  @override
  Future<Either<Failure, String>> ensureBriefingCached(String assessmentId) async {
    return const Left(NetworkFailure());
  }
}

void main() {
  testWidgets(
    'a NotScorableFailure never renders a risk percentage or a BandChip, '
    'through the real RiskDashboardScreen and provider stack',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riskRepositoryProvider.overrideWithValue(const _NotScorableRepository()),
            localisationProvider.overrideWithValue(
              const InMemoryLocalisations(BuiltinLocale.en),
            ),
          ],
          child: const MaterialApp(
            home: RiskDashboardScreen(parcelId: 'p1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The system worked and declined to guess - CLAUDE.md S1's central
      // invariant. There is structurally nowhere in this render for a score
      // to appear: no RiskRing widget is even in the tree, no BandChip, and
      // no text anywhere contains a '%'.
      expect(find.byType(RiskRing), findsNothing);
      expect(find.byType(BandChip), findsNothing);
      expect(find.textContaining('%'), findsNothing);

      // Positive check, not just an absence: it actually rendered the C3
      // not-scorable explanation, not a blank screen (which would also
      // satisfy the three assertions above for the wrong reason).
      expect(find.byType(NotScorableView), findsOneWidget);
      expect(find.text('We cannot tell you today'), findsOneWidget);
    },
  );
}
