import '../../../core/network/authenticated_api_client.dart';
import '../domain/game_models.dart';
import '../domain/game_repository.dart';
import 'game_mapper.dart';

class GameRepositoryImpl implements GameRepository, ForfeitableGameRepository {
  final AuthenticatedApiClient _client;
  const GameRepositoryImpl(this._client);
  @override
  Future<PuzzleAttempt> startOrResume(String id) async {
    final j = await _client.request('POST', '/api/v1/game/levels/$id/attempts',
        data: <String, dynamic>{});
    return attemptFromJson(Map<String, dynamic>.from(j['attempt'] as Map));
  }

  @override
  Future<PuzzleAttempt> getAttempt(String id) async {
    final j = await _client.request('GET', '/api/v1/game/attempts/$id');
    return attemptFromJson(Map<String, dynamic>.from(j['attempt'] as Map));
  }

  @override
  Future<LetterResult> submitLetter(
      {required String attemptId,
      required int position,
      required String letter,
      required String requestId}) async {
    final j = await _client.request(
        'PATCH', '/api/v1/game/attempts/$attemptId/cells/$position',
        data: {'letter': letter, 'requestId': requestId});
    return letterFromJson(j);
  }

  @override
  Future<HintResult> revealHint(
      {required String attemptId, required int position}) async {
    final j = await _client.request(
        'POST', '/api/v1/game/attempts/$attemptId/hints/reveal',
        data: {'position': position});
    return hintFromJson(j);
  }

  @override
  Future<PuzzleNote> saveNote(
      {required String attemptId,
      required int number,
      required String? letter,
      required String comment}) async {
    final j = await _client.request(
        'PUT', '/api/v1/game/attempts/$attemptId/notes/$number',
        data: {'letter': letter, 'comment': comment});
    return noteFromJson(Map<String, dynamic>.from(j['note'] as Map));
  }

  @override
  Future<BonusResult> answerBonus(
      {required String attemptId, required String? guessedCreatorId}) async {
    final j = await _client.request(
        'POST', '/api/v1/game/attempts/$attemptId/bonus',
        data: {'guessedCreatorId': guessedCreatorId});
    return bonusFromJson(j);
  }

  @override
  Future<ForfeitResult> abandonAttempt(String id) async {
    final j = await _client.request('POST', '/api/v1/game/attempts/$id/abandon',
        data: <String, dynamic>{});
    return forfeitFromJson(j);
  }
}
