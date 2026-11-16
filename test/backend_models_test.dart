import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/catalog/data/catalog_mapper.dart';
import 'package:blogergrame/features/game/data/game_mapper.dart';
import 'package:blogergrame/features/economy/data/economy_mapper.dart';
import 'package:blogergrame/features/auth/data/secure_session_store.dart';

void main() {
  test('catalog metadata contains no answer', () {
    final level = levelFromJson({
      'id': 'b99af471-2dda-43b9-ac23-13a8397e4a3a',
      'category': 'streamers', 'number': 1, 'difficulty': 'easy',
      'letters': 19, 'preview': true, 'completed': false,
    });
    expect(level.id, isA<String>());
    expect(level.letters, 19);
    expect(level.preview, isTrue);
  });

  test('equal numbers do not fill each other', () {
    final attempt = attemptFromJson({
      'id': '0b127466-2b34-40f4-b5e1-9b4c76b571c9',
      'levelId': 'b99af471-2dda-43b9-ac23-13a8397e4a3a',
      'category': 'streamers', 'levelNumber': 1,
      'status': 'in_progress', 'mistakes': 0,
      'triesRemaining': 3, 'triesPerLife': 3,
      'notes': [], 'bonusAnswered': false,
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

  test('token pair remains one protected storage record', () {
    final session = StoredGuestSession.fromResponse({
      'accessToken': 'test-access', 'refreshToken': 'test-refresh',
      'accessExpiresAt': '2030-01-01T00:15:00.000Z',
      'refreshExpiresAt': '2030-02-01T00:00:00.000Z',
    });
    final restored = StoredGuestSession.fromJson(session.toJson());
    expect(restored.accessToken, session.accessToken);
    expect(restored.refreshToken, session.refreshToken);
  });

  test('wallet parses server recovery timestamp', () {
    final wallet = walletFromJson({
      'coins': 30, 'lives': 4, 'hints': 2,
      'maxLives': 5, 'maxHints': 20,
      'lifeRegenMinutes': 30,
      'nextLifeAt': '2030-01-01T00:30:00.000Z',
    });
    expect(wallet.nextLifeAt?.toUtc().minute, 30);
    expect(wallet.lifeRegenMinutes, 30);
  });

  test('wrong answer does not get a cell or reward', () {
    final result = letterFromJson({
      'correct': false, 'position': 4, 'mistakes': 3,
      'triesRemaining': 3, 'lostLife': true, 'locked': false,
      'wallet': {
        'coins': 30, 'lives': 4, 'hints': 2,
        'maxLives': 5, 'maxHints': 20, 'lifeRegenMinutes': 30,
        'nextLifeAt': '2030-01-01T00:30:00.000Z',
      },
    });
    expect(result.correct, isFalse);
    expect(result.cell, isNull);
    expect(result.rewardCoins, 0);
    expect(result.wallet?.lives, 4);
  });

  test('offer price comes from backend response', () {
    final offer = offerFromJson({
      'sku': 'life_1', 'kind': 'lives', 'quantity': 1, 'costCoins': 50,
    });
    expect(offer.costCoins, 50);
    expect(offer.kind, 'lives');
  });
}
