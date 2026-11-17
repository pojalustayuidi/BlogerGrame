import 'game_models.dart';

abstract class GameRepository {
  Future<PuzzleAttempt> startOrResume(String levelId);
  Future<PuzzleAttempt> getAttempt(String attemptId);
  Future<LetterResult> submitLetter(
      {required String attemptId,
      required int position,
      required String letter,
      required String requestId});
  Future<HintResult> revealHint(
      {required String attemptId, required int position});
  Future<PuzzleNote> saveNote(
      {required String attemptId,
      required int number,
      required String? letter,
      required String comment});
  Future<BonusResult> answerBonus(
      {required String attemptId, required String? guessedCreatorId});
}

/// Separate capability: avoids changing older GameRepository mocks using implements.
abstract class ForfeitableGameRepository {
  Future<ForfeitResult> abandonAttempt(String attemptId);
}
