import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/risk_assessment_model.dart';
import 'risk_remote_data_source.dart';

/// HTTP implementation of [RiskRemoteDataSource]. See `docs/api-contract.md`
/// for the exact wire shapes this parses.
final class RiskRemoteDataSourceImpl implements RiskRemoteDataSource {
  const RiskRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<RiskAssessmentModel> fetchLatestAssessment(String parcelId) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        '/v1/parcels/$parcelId/risk-assessment',
      );
    } on DioException catch (error) {
      throw _translate(error);
    }

    final body = response.data;
    if (body == null) {
      throw const FormatException('Empty response body for risk assessment');
    }

    // Not-scorable is a successful response about a valid parcel, not a
    // client error - see docs/api-contract.md for why this is never a 4xx.
    if (body['scorable'] == false) {
      final reasonKey = body['reason_key'];
      if (reasonKey is! String) {
        throw const FormatException(
          'Not-scorable response missing a string reason_key',
        );
      }
      throw NotScorableException(reasonKey: reasonKey);
    }

    return RiskAssessmentModel.fromJson(body);
  }

  @override
  Future<List<int>> downloadBriefing(String assessmentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/v1/briefings/$assessmentId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) {
        throw const FormatException('Empty response body for briefing audio');
      }
      return bytes;
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  Exception _translate(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthException();
    }
    if (statusCode != null) {
      return ServerException(statusCode: statusCode);
    }
    // No response reached at all: DNS failure, connection refused, or the
    // connect-timeout configured in core/network/dio_client.dart.
    return const NetworkException();
  }
}
