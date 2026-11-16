import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/core/backend/backend_models.dart';
import 'package:blogergrame/core/backend/secure_session_store.dart';

void main() {
  test('catalog metadata never depends on a disclosed quote', () {
    final level = LevelSummary.fromJson({
      'id': 'b99af471-2dda-43b9-ac23-13a8397e4a3a',
      'category': 'streamers',
      'number': 1,
      'difficulty': 'easy',
      'letters': 19,
      'preview': true,
      'completed': false,
    });
    expect(level.id, isA<String>());
    expect(level.letters, 19);
    expect(level.preview, isTrue);
  });

  test('same cipher number does not automatically fill another cell', () {
    final attempt = PuzzleAttempt.fromJson({
      'id': '0b127466-2b34-40f4-b5e1-9b4c76b571c9',
      'levelId': 'b99af471-2dda-43b9-ac23-13a8397e4a3a',
      'category': 'streamers',
      'levelNumber': 1,
      'status': 'in_progress',
      'mistakes': 0,
      'triesRemaining': 3,
      'triesPerLife': 3,
      'notes': [],
      'bonusAnswered': false,
      'layout': [
        {'position': 0, 'type': 'letter', 'number': 8, 'given': null, 'letter': 'А'},
        {'position': 1, 'type': 'letter', 'number': 8, 'given': null, 'letter': null},
        {'position': 2, 'type': 'separator', 'value': ' '},
      ],
    });
    expect(attempt.layout[0].isFilled, isTrue);
    expect(attempt.layout[1].isFilled, isFalse);
    expect(attempt.layout[0].number, attempt.layout[1].number);
    expect(attempt.layout[2].isLetter, isFalse);
  });

  test('secure session encodes both tokens in one JSON record', () {
    final session = StoredGuestSession.fromResponse({
      'accessToken': 'test-access',
      'refreshToken': 'test-refresh',
      'accessExpiresAt': '2030-01-01T00:15:00.000Z',
      'refreshExpiresAt': '2030-02-01T00:00:00.000Z',
    });
    final restored = StoredGuestSession.fromJson(session.toJson());
    expect(restored.accessToken, session.accessToken);
    expect(restored.refreshToken, session.refreshToken);
  });

  test('wallet accepts nullable nextLifeAt', () {
    final wallet = GameWallet.fromJson({
      'coins': 30, 'lives': 5, 'hints': 2,
      'maxLives': 5, 'maxHints': 20,
      'lifeRegenMinutes': 30, 'nextLifeAt': null,
    });
    expect(wallet.nextLifeAt, isNull);
    expect(wallet.lifeRegenMinutes, 30);
  });
}
