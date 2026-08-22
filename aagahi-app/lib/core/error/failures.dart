import 'package:equatable/equatable.dart';

/// What the presentation layer switches on. `Failure` never carries a raw
/// exception or stack trace - those are logged at the point they're caught in
/// the repository (see `data/repositories/risk_repository_impl.dart`) and do
/// not need to survive past that boundary.
///
/// There is deliberately no `UnknownFailure` or default case anywhere this
/// type is consumed. Every failure the app can show is named here; a failure
/// mode that isn't belongs in this file, not behind a fallback branch.
abstract base class Failure extends Equatable {
  const Failure({required this.messageKey});

  /// Localisation key for the headline message shown to the user.
  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}

final class NetworkFailure extends Failure {
  const NetworkFailure() : super(messageKey: 'failure.network');
}

final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode}) : super(messageKey: 'failure.server');

  final int? statusCode;

  @override
  List<Object?> get props => [messageKey, statusCode];
}

final class CacheFailure extends Failure {
  const CacheFailure() : super(messageKey: 'failure.cache');
}

final class AuthFailure extends Failure {
  const AuthFailure() : super(messageKey: 'failure.auth');
}

/// The cell could not be scored - satellite coverage was insufficient, not
/// that something broke. See CLAUDE.md S1: this is never collapsed into a
/// generic error, and the UI must never show a score or a band alongside it.
final class NotScorableFailure extends Failure {
  const NotScorableFailure({required this.reasonKey})
      : super(messageKey: 'failure.notScorable');

  /// Localisation key naming the missing input in plain language
  /// (FR-PRED-009), e.g. `failure.notScorable.reason.soilMoistureGap`.
  final String reasonKey;

  @override
  List<Object?> get props => [messageKey, reasonKey];
}
