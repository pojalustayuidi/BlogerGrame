import 'package:dio/dio.dart';

class BackendException implements Exception {
  final String code;
  final int? httpStatus;
  final String message;

  const BackendException(this.code, this.message, {this.httpStatus});

  factory BackendException.fromDio(DioException error) {
    final response = error.response;
    final body = response?.data;
    final code = body is Map && body['error'] is String
        ? body['error'] as String
        : 'NETWORK_ERROR';
    if (response != null) {
      return BackendException(code, 'Сервер ответил: $code',
          httpStatus: response.statusCode);
    }
    return const BackendException(
      'NETWORK_ERROR',
      'Нет соединения с локальным backend. Проверьте npm run dev и adb reverse tcp:8085 tcp:8085.',
    );
  }

  @override
  String toString() => message;
}
