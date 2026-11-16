import 'game_models.dart';

abstract class GameRepository {
  Future<PuzzleAttempt> startOrResume(String levelId);
  Future<PuzzleAttempt> getAttempt(String attemptId);

  /// requestId MUST be reused when retrying the same letter operation.
  Future<LetterResult> submitLetter({
    required String attemptId,
    required int position,
    required String letter,
    required String requestId,
  });

  Future<HintResult> revealHint({required String attemptId,
    required int position});

  Future<PuzzleNote> saveNote({required String attemptId,
    required int number, required String? letter, required String comment});

  /// null explicitly skips the optional creator question.
  Future<BonusResult> answerBonus({required String attemptId,
    required String? guessedCreatorId});
}
