import 'package:aagahi/core/error/exceptions.dart';
import 'package:aagahi/features/risk/data/datasources/risk_remote_data_source_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

const _path = '/v1/parcels/p1/risk-assessment';

Response<T> _response<T>(T? data, {int statusCode = 200}) => Response<T>(
      requestOptions: RequestOptions(path: _path),
      data: data,
      statusCode: statusCode,
    );

DioException _errorWithResponse(int statusCode) => DioException(
      requestOptions: RequestOptions(path: _path),
      response: Response(
          requestOptions: RequestOptions(path: _path), statusCode: statusCode),
    );

DioException get _connectionFailure => DioException(
      requestOptions: RequestOptions(path: _path),
      type: DioExceptionType.connectionTimeout,
    );

/// Every branch of `docs/api-contract.md`'s error table, exercised against
/// a mocked Dio - no real network involved. The one branch worth reading
/// closely: not-scorable must never be reachable via a thrown DioException,
/// only via a 200 body with `scorable: false` (CLAUDE.md §1, the
/// api-contract.md rationale for why this is never a 4xx).
void main() {
  late _MockDio dio;
  late RiskRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    dataSource = RiskRemoteDataSourceImpl(dio);
  });

  group('fetchLatestAssessment', () {
    test('parses a scored 200 body into a RiskAssessmentModel', () async {
      when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => _response({
          'parcelId': 'p1',
          'assessedOn': '2026-08-23T00:00:00.000Z',
          'probability': 0.71,
          'riskBand': 'warning',
          'horizonDays': 14,
          'drivers': <dynamic>[],
          'trace': <dynamic>[],
          'modelVersion': 'v1',
          'completenessRatio': 1.0,
          'confidenceLower': 0.6,
          'confidenceUpper': 0.8,
          'usedDegradedInputs': false,
        }),
      );

      final model = await dataSource.fetchLatestAssessment('p1');

      expect(model.entity.parcelId, 'p1');
      expect(model.entity.probability, 0.71);
    });

    test(
      'a 200 body with scorable:false throws NotScorableException with the '
      'reason key - not-scorable is a successful response, not an error',
      () async {
        when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => _response({
            'scorable': false,
            'reason_key': 'notScorable.insufficientCoverage',
          }),
        );

        await expectLater(
          () => dataSource.fetchLatestAssessment('p1'),
          throwsA(
            isA<NotScorableException>().having(
              (e) => e.reasonKey,
              'reasonKey',
              'notScorable.insufficientCoverage',
            ),
          ),
        );
      },
    );

    test('401 throws AuthException', () async {
      when(() => dio.get<Map<String, dynamic>>(any()))
          .thenThrow(_errorWithResponse(401));

      await expectLater(
        () => dataSource.fetchLatestAssessment('p1'),
        throwsA(isA<AuthException>()),
      );
    });

    test('403 throws AuthException', () async {
      when(() => dio.get<Map<String, dynamic>>(any()))
          .thenThrow(_errorWithResponse(403));

      await expectLater(
        () => dataSource.fetchLatestAssessment('p1'),
        throwsA(isA<AuthException>()),
      );
    });

    test(
        '500 throws ServerException carrying the status code - never NotScorable',
        () async {
      when(() => dio.get<Map<String, dynamic>>(any()))
          .thenThrow(_errorWithResponse(500));

      await expectLater(
        () => dataSource.fetchLatestAssessment('p1'),
        throwsA(isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('a connection timeout with no response throws NetworkException',
        () async {
      when(() => dio.get<Map<String, dynamic>>(any()))
          .thenThrow(_connectionFailure);

      await expectLater(
        () => dataSource.fetchLatestAssessment('p1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('an empty 200 body throws FormatException rather than a null crash',
        () async {
      when(() => dio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => _response(null));

      await expectLater(
        () => dataSource.fetchLatestAssessment('p1'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('downloadBriefing', () {
    test('returns the raw bytes on 200', () async {
      final bytes = [1, 2, 3, 4];
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _response(bytes));

      final result = await dataSource.downloadBriefing('assessment-1');

      expect(result, bytes);
    });

    test('a connection failure throws NetworkException', () async {
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenThrow(_connectionFailure);

      await expectLater(
        () => dataSource.downloadBriefing('assessment-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
