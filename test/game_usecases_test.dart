import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/domain/game_repository.dart';
import 'package:blogergrame/features/game/domain/usecases/submit_letter.dart';

class _RecordingRepository extends Fake implements GameRepository {
  final List<String> requestIds = [];

  @override
  Future<LetterResult> submitLetter({required String attemptId,
    required int position, required String letter,
    required String requestId}) async {
    requestIds.add(requestId);
    return LetterResult(
      correct: false, position: position, mistakes: 1,
      triesRemaining: 2, lostLife: false, locked: false,
      solved: false, replayed: false, cell: null,
      wallet: null, rewardCoins: 0, flawless: false,
      bonusOptions: const [],
    );
  }
}

void main() {
  test('retrying the same letter preserves requestId', () async {
    final repository = _RecordingRepository();
    final submit = SubmitLetter(repository);
    const id = 'e22a8f35-c6f5-47c3-9dd7-25d94fd5e57a';
    for (var i = 0; i < 2; i++) {
      await submit(attemptId: 'attempt', position: 7,
        letter: 'А', requestId: id);
    }
    expect(repository.requestIds, [id, id]);
  });
}
