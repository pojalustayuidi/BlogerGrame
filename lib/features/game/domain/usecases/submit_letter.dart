import '../game_models.dart';
import '../game_repository.dart';

/// Deliberately accepts a requestId from the caller. Retrying a keypress with
/// a NEW ID could charge an extra mistake; UI/application state must retain it.
class SubmitLetter {
  final GameRepository repository;

  const SubmitLetter(this.repository);

  Future<LetterResult> call({required String attemptId,
    required int position, required String letter, required String requestId}) =>
      repository.submitLetter(attemptId: attemptId, position: position,
        letter: letter, requestId: requestId);
}
