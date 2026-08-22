/// Exceptions live at the data-layer boundary. A repository catches every
/// one of these and converts it to a `Failure` (see `core/error/failures.dart`)
/// before it reaches domain or presentation code - see CLAUDE.md S3.
library;

final class CacheException implements Exception {
  const CacheException([this.message = 'Local cache operation failed']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

final class NetworkException implements Exception {
  const NetworkException([this.message = 'No network connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

final class ServerException implements Exception {
  const ServerException({this.statusCode, this.message = 'Server error'});

  final int? statusCode;
  final String message;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

final class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed']);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Thrown by the remote data source when the server reports the cell as
/// NOT_SCORABLE (FR-PRED-009), as distinct from any other server failure -
/// the repository must never fold this into a generic `ServerFailure`.
final class NotScorableException implements Exception {
  const NotScorableException({required this.reasonKey});

  final String reasonKey;

  @override
  String toString() => 'NotScorableException: $reasonKey';
}
