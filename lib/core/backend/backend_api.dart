import 'package:dio/dio.dart';
import 'backend_config.dart';
import 'backend_exception.dart';
import 'backend_models.dart';
import 'guest_session_manager.dart';
import 'secure_session_store.dart';

/// Authenticated adapter for the v1 backend. Does not alter existing legacy
/// services/providers yet; the UI migration can be done in small patches.
class BackendApi {
  late final Dio _dio;
  late final GuestSessionManager sessions;

  BackendApi({Dio? dio, SecureSessionStore? sessionStore}) {
    final opts = BaseOptions(
      baseUrl: BackendConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    );
    _dio = dio ?? Dio(opts);
    final publicDio = Dio(opts);
    sessions = GuestSessionManager(publicDio, sessionStore ?? SecureSessionStore());
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final session = await sessions.ensureSession();
    Future<Response<dynamic>> send(String accessToken) => _dio.request<dynamic>(
          path,
          data: data,
          queryParameters: query,
          options: Options(method: method, headers: {'Authorization': 'Bearer $accessToken'}),
        );
    Response<dynamic> response;
    try {
      response = await send(session.accessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) throw BackendException.fromDio(e);
      final refreshed = await sessions.refreshAfterUnauthorized(session.accessToken);
      try {
        response = await send(refreshed.accessToken);
      } on DioException catch (retryError) {
        throw BackendException.fromDio(retryError);
      }
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<String> getPlayerId() async {
    final json = await _request('GET', '/api/v1/auth/me');
    return (json['player'] as Map)['id'] as String;
  }

  Future<List<GameCategory>> categories() async {
    final json = await _request('GET', '/api/v1/game/categories');
    return (json['categories'] as List<dynamic>)
        .map((x) => GameCategory.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList(growable: false);
  }

  Future<List<LevelSummary>> levels({String? category}) async {
    final json = await _request('GET', '/api/v1/game/levels',
        query: category == null ? null : {'category': category});
    return (json['levels'] as List<dynamic>)
        .map((x) => LevelSummary.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList(growable: false);
  }

  Future<GameWallet> wallet() async {
    final json = await _request('GET', '/api/v1/game/wallet');
    return GameWallet.fromJson(Map<String, dynamic>.from(json['wallet'] as Map));
  }

  Future<PuzzleAttempt> startOrResumeLevel(String levelId) async {
    final json = await _request('POST', '/api/v1/game/levels/$levelId/attempts',
        data: <String, dynamic>{});
    return PuzzleAttempt.fromJson(Map<String, dynamic>.from(json['attempt'] as Map));
  }

  Future<PuzzleAttempt> attempt(String attemptId) async {
    final json = await _request('GET', '/api/v1/game/attempts/$attemptId');
    return PuzzleAttempt.fromJson(Map<String, dynamic>.from(json['attempt'] as Map));
  }

  /// Per-letter validation. The caller must generate a NEW UUID for each new
  /// keypress and reuse it if the same network request is retried.
  Future<Map<String, dynamic>> enterLetter({
    required String attemptId,
    required int position,
    required String letter,
    required String requestId,
  }) => _request('PATCH', '/api/v1/game/attempts/$attemptId/cells/$position',
      data: {'letter': letter, 'requestId': requestId});

  Future<Map<String, dynamic>> revealHint({
    required String attemptId,
    required int position,
  }) => _request('POST', '/api/v1/game/attempts/$attemptId/hints/reveal',
      data: {'position': position});

  Future<Map<String, dynamic>> updateNote({
    required String attemptId,
    required int number,
    required String? letter,
    required String comment,
  }) => _request('PUT', '/api/v1/game/attempts/$attemptId/notes/$number',
      data: {'letter': letter, 'comment': comment});

  Future<Map<String, dynamic>> answerBonus({
    required String attemptId,
    required String? guessedCreatorId,
  }) => _request('POST', '/api/v1/game/attempts/$attemptId/bonus',
      data: {'guessedCreatorId': guessedCreatorId});

  Future<List<Map<String, dynamic>>> shopOffers() async {
    final json = await _request('GET', '/api/v1/game/shop');
    return (json['offers'] as List<dynamic>)
        .map((x) => Map<String, dynamic>.from(x as Map)).toList(growable: false);
  }

  Future<Map<String, dynamic>> buyShopItem({
    required String sku,
    required String requestId,
  }) => _request('POST', '/api/v1/game/shop/purchases',
      data: {'sku': sku, 'requestId': requestId});
}
