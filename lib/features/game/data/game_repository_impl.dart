import '../../../core/network/authenticated_api_client.dart';
import '../domain/game_models.dart';
import '../domain/game_repository.dart';
import 'game_mapper.dart';

class GameRepositoryImpl implements GameRepository {
  final AuthenticatedApiClient _client;

  const GameRepositoryImpl(this._client);

  @override
  Future<PuzzleAttempt> startOrResume(String levelId) async {
    final json = await _client.request('POST',
        '/api/v1/game/levels/$levelId/attempts', data: <String, dynamic>{});
    return attemptFromJson(Map<String, dynamic>.from(json['attempt'] as Map));
  }

  @override
  Future<PuzzleAttempt> getAttempt(String attemptId) async {
    final json = await _client.request('GET', '/api/v1/game/attempts/$attemptId');
    return attemptFromJson(Map<String, dynamic>.from(json['attempt'] as Map));
  }

  @override
  Future<LetterResult> submitLetter({
    required String attemptId,
    required int position,
    required String letter,
    required String requestId,
  }) async {
    final json = await _client.request('PATCH',
        '/api/v1/game/attempts/$attemptId/cells/$position',
        data: {'letter': letter, 'requestId': requestId});
    return letterFromJson(json);
  }

  @override
  Future<HintResult> revealHint({required String attemptId,
    required int position}) async {
    final json = await _client.request('POST',
        '/api/v1/game/attempts/$attemptId/hints/reveal',
        data: {'position': position});
    return hintFromJson(json);
  }

  @override
  Future<PuzzleNote> saveNote({required String attemptId,
    required int number, required String? letter,
    required String comment}) async {
    final json = await _client.request('PUT',
        '/api/v1/game/attempts/$attemptId/notes/$number',
        data: {'letter': letter, 'comment': comment});
    return noteFromJson(Map<String, dynamic>.from(json['note'] as Map));
  }

  @override
  Future<BonusResult> answerBonus({required String attemptId,
    required String? guessedCreatorId}) async {
    final json = await _client.request('POST',
        '/api/v1/game/attempts/$attemptId/bonus',
        data: {'guessedCreatorId': guessedCreatorId});
    return bonusFromJson(json);
  }
}
