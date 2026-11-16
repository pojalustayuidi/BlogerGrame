import 'package:dio/dio.dart';
import 'access_token_source.dart';
import 'backend_exception.dart';

/// HTTP transport only. No game rules, DTOs or feature logic here.
class AuthenticatedApiClient {
  final Dio _dio;
  final AccessTokenSource _tokens;

  const AuthenticatedApiClient(this._dio, this._tokens);

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final usedToken = await _tokens.getAccessToken();
    Future<Response<dynamic>> send(String token) => _dio.request<dynamic>(
          path,
          data: data,
          queryParameters: query,
          options: Options(
            method: method,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );

    Response<dynamic> response;
    try {
      response = await send(usedToken);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        throw BackendException.fromDio(error);
      }
      final newToken = await _tokens.recoverFromUnauthorized(usedToken);
      try {
        // A 401 means the backend has rejected this operation before execution.
        response = await send(newToken);
      } on DioException catch (retryError) {
        throw BackendException.fromDio(retryError);
      }
    }

    final json = response.data;
    if (json is! Map) {
      throw const BackendException('INVALID_RESPONSE',
          'Сервер вернул неожиданный формат JSON.');
    }
    return Map<String, dynamic>.from(json);
  }
}
