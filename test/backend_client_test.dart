import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/core/network/access_token_source.dart';
import 'package:blogergrame/core/network/authenticated_api_client.dart';
import 'package:blogergrame/features/game/data/game_repository_impl.dart';

class _Tokens implements AccessTokenSource {
  String token = 'first';
  int refreshCount = 0;

  @override
  Future<String> getAccessToken() async => token;

  @override
  Future<String> recoverFromUnauthorized(String usedAccessToken) async {
    expect(usedAccessToken, 'first');
    refreshCount++;
    token = 'second';
    return token;
  }
}

void main() {
  test('401 requests one token refresh then retries with new bearer', () async {
    final tokens = _Tokens();
    final seen = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8085'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      seen.add(options.headers['Authorization'] as String);
      if (seen.length == 1) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401,
              data: {'error': 'UNAUTHORIZED'}),
        ));
      } else {
        handler.resolve(Response(requestOptions: options, statusCode: 200,
            data: {'categories': <dynamic>[]}));
      }
    }));

    final client = AuthenticatedApiClient(dio, tokens);
    final result = await client.request('GET', '/api/v1/game/categories');
    expect(result['categories'], isEmpty);
    expect(seen, ['Bearer first', 'Bearer second']);
    expect(tokens.refreshCount, 1);
  });

  test('letter endpoint forwards exact requestId and no client-side reward', () async {
    final tokens = _Tokens();
    RequestOptions? observed;
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8085'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      observed = options;
      handler.resolve(Response(requestOptions: options, statusCode: 200,
          data: {'correct': false, 'position': 4, 'mistakes': 1,
            'triesRemaining': 2, 'lostLife': false, 'locked': false}));
    }));
    final repository = GameRepositoryImpl(AuthenticatedApiClient(dio, tokens));
    const requestId = 'e22a8f35-c6f5-47c3-9dd7-25d94fd5e57a';
    final result = await repository.submitLetter(
      attemptId: 'an-attempt-id', position: 4, letter: 'В', requestId: requestId);
    expect(observed?.method, 'PATCH');
    expect(observed?.path, '/api/v1/game/attempts/an-attempt-id/cells/4');
    expect(observed?.data, {'letter': 'В', 'requestId': requestId});
    expect(result.triesRemaining, 2);
    expect(result.correct, isFalse);
  });
}
