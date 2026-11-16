import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blogergrame/core/network/backend_exception.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/domain/game_repository.dart';
import 'package:blogergrame/features/home/data/home_attempt_store.dart';

class _FakeGameRepository extends Fake implements GameRepository {
  _FakeGameRepository(this.load);
  final Future<PuzzleAttempt> Function(String id) load;

  @override
  Future<PuzzleAttempt> getAttempt(String attemptId) => load(attemptId);
}

PuzzleAttempt _attempt({String status = 'in_progress'}) => PuzzleAttempt(
  id: 'attempt-42', levelId: 'level-1', category: 'streamers',
  levelNumber: 1, status: status, mistakes: 1,
  triesRemaining: 2, triesPerLife: 3,
  layout: const [], notes: const [], bonusOptions: const [],
  bonusAnswered: false,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persisted attempt belongs only to the expected guest', () async {
    final store = HomeAttemptStore();
    await store.save('guest-1', _attempt());
    expect(await store.read('guest-1'), 'attempt-42');
    expect(await store.read('guest-2'), isNull);
  });

  test('existing attempt ID is revalidated through the backend', () async {
    final store = HomeAttemptStore();
    await store.save('guest-1', _attempt());
    final repo = _FakeGameRepository((id) async {
      expect(id, 'attempt-42');
      return _attempt();
    });
    final result = await store.loadValidated('guest-1', repo);
    expect(result?.id, 'attempt-42');
  });

  test('finished attempt is cleared, no false resume action', () async {
    final store = HomeAttemptStore();
    await store.save('guest-1', _attempt());
    final repo = _FakeGameRepository((_) async => _attempt(status: 'solved'));
    expect(await store.loadValidated('guest-1', repo), isNull);
    expect(await store.read('guest-1'), isNull);
  });

  test('network errors do NOT discard a saved guest attempt', () async {
    final store = HomeAttemptStore();
    await store.save('guest-1', _attempt());
    final repo = _FakeGameRepository((_) async =>
      throw const BackendException('NETWORK_ERROR', 'Offline'));
    await expectLater(store.loadValidated('guest-1', repo), throwsA(
      isA<BackendException>(),
    ));
    expect(await store.read('guest-1'), 'attempt-42');
  });

  test('server 404 invalidates only stale pointer', () async {
    final store = HomeAttemptStore();
    await store.save('guest-1', _attempt());
    final repo = _FakeGameRepository((_) async =>
      throw const BackendException('ATTEMPT_NOT_FOUND', 'Not found', httpStatus: 404));
    expect(await store.loadValidated('guest-1', repo), isNull);
    expect(await store.read('guest-1'), isNull);
  });
}
