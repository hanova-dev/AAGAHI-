import 'package:dio/dio.dart';

/// A reserved, never-resolving address (RFC 2606) - deliberately, so the
/// app fails fast and predictably when no backend has been deployed,
/// rather than silently pointing at a stray real host. Override via
/// `--dart-define=API_BASE_URL=...` once a real API exists. See
/// docs/api-contract.md.
const _defaultBaseUrl = 'https://api.aagahi.invalid';

/// Builds the [Dio] client used for all AAGAHI API calls.
///
/// `connectTimeout` is 5 seconds, not Dio's default of none: a demo
/// audience should see the offline-cache fallback within seconds when no
/// backend is configured, not wait out an indefinite hang to find out
/// there is none.
Dio buildDio({String baseUrl = _defaultBaseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
    ),
  );
}
