import '../game_models.dart';
import '../game_repository.dart';

class StartOrResumeAttempt {
  final GameRepository repository;

  const StartOrResumeAttempt(this.repository);

  Future<PuzzleAttempt> call(String levelId) =>
      repository.startOrResume(levelId);
}
