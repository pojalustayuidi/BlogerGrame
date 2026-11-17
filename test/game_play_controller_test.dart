import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/economy/domain/economy_models.dart';
import 'package:blogergrame/features/economy/domain/economy_repository.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/domain/game_repository.dart';
import 'package:blogergrame/features/game/presentation/game_pending_store.dart';
import 'package:blogergrame/features/game/presentation/game_play_controller.dart';
import 'package:blogergrame/features/game/presentation/game_ui_logic.dart';

const _wallet = GameWallet(
  coins: 30,
  lives: 5,
  hints: 2,
  maxLives: 5,
  maxHints: 5,
  lifeRegenMinutes: 30,
  nextLifeAt: null,
);

PuzzleAttempt _attempt({
  List<PuzzleCell>? cells,
  int mistakes = 0,
  String status = 'in_progress',
}) => PuzzleAttempt(
  id: 'attempt-test', levelId: 'level-test', category: 'streamers',
  levelNumber: 1, status: status, mistakes: mistakes,
  triesRemaining: 3 - mistakes % 3, triesPerLife: 3,
  layout: cells ?? const [
    PuzzleCell(position: 0, type: 'letter', number: 7),
    PuzzleCell(position: 1, type: 'letter', number: 7),
  ],
  notes: const [], bonusOptions: const [], bonusAnswered: false,
);

class _MemoryStore extends PendingLetterStore {
  PendingLetterRequest? saved;
  @override
  Future<PendingLetterRequest?> read(String attemptId) async => saved;
  @override
  Future<void> save(PendingLetterRequest request) async { saved = request; }
  @override
  Future<void> clear(String attemptId) async { saved = null; }
}

class _FakeEconomy implements EconomyRepository {
  @override
  Future<GameWallet> wallet() async => _wallet;
  @override
  Future<List<ShopOffer>> shopOffers() async => const [];
  @override
  Future<PurchaseReceipt> buyShopItem({
    required String sku, required String requestId,
  }) => throw UnimplementedError();
}

class _FakeGame implements GameRepository {
  PuzzleAttempt current = _attempt();
  int requests = 0;
  final ids = <String>[];
  bool firstTimeout = false;
  bool wrong = false;

  @override
  Future<PuzzleAttempt> getAttempt(String attemptId) async => current;
  @override
  Future<PuzzleAttempt> startOrResume(String levelId) async => current;

  @override
  Future<LetterResult> submitLetter({
    required String attemptId, required int position,
    required String letter, required String requestId,
  }) async {
    requests++;
    ids.add(requestId);
    if (firstTimeout && requests == 1) throw StateError('timeout');
    final nextMistakes = current.mistakes + (wrong ? 1 : 0);
    if (!wrong) {
      current = _attempt(cells: [
        for (final cell in current.layout)
          PuzzleCell(position: cell.position, type: cell.type,
              number: cell.number, given: cell.given,
              letter: cell.position == position ? letter : cell.letter),
      ]);
    } else {
      current = _attempt(mistakes: nextMistakes, cells: current.layout);
    }
    return LetterResult(
      correct: !wrong,
      position: position,
      mistakes: current.mistakes,
      triesRemaining: current.triesRemaining,
      lostLife: wrong && nextMistakes % 3 == 0,
      locked: false, solved: false, replayed: requests > 1 && firstTimeout,
      cell: wrong ? null : selectedCell(current, position),
      wallet: _wallet, rewardCoins: 0, flawless: false,
      bonusOptions: const [],
    );
  }

  @override
  Future<HintResult> revealHint({
    required String attemptId, required int position,
  }) async {
    current = _attempt(cells: [
      for (final cell in current.layout)
        PuzzleCell(position: cell.position, type: cell.type,
          number: cell.number, given: cell.given,
          letter: cell.position == position ? 'А' : cell.letter,
          hinted: cell.position == position),
    ]);
    return HintResult(applied: true,
      cell: selectedCell(current, position)!,
      solved: false, rewardCoins: 0,
      wallet: _wallet, bonusOptions: const []);
  }

  @override
  Future<PuzzleNote> saveNote({
    required String attemptId, required int number,
    required String? letter, required String comment,
  }) async => PuzzleNote(number: number, letter: letter, comment: comment);

  @override
  Future<BonusResult> answerBonus({
    required String attemptId, required String? guessedCreatorId,
  }) => throw UnimplementedError();
}

void main() {
  test('same cipher number remains independently editable by position', () async {
    final repo = _FakeGame();
    final controller = PrufaniGameController(
      initialAttempt: repo.current, gameRepository: repo,
      economyRepository: _FakeEconomy(), pendingStore: _MemoryStore(),
      newRequestId: () => '11111111-1111-4111-8111-111111111111',
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.input('а');
    expect(controller.snapshot.attempt.layout[0].letter, 'А');
    expect(controller.snapshot.attempt.layout[1].letter, isNull);
    expect(controller.snapshot.selectedPosition, 1);
    expect(controller.snapshot.attempt.layout[0].number,
        controller.snapshot.attempt.layout[1].number);
  });

  test('wrong letter stays empty and server mistake count is used', () async {
    final repo = _FakeGame()..wrong = true;
    final controller = PrufaniGameController(initialAttempt: repo.current,
      gameRepository: repo, economyRepository: _FakeEconomy(),
      pendingStore: _MemoryStore());
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.input('Б');
    expect(controller.snapshot.attempt.layout[0].letter, isNull);
    expect(controller.snapshot.attempt.mistakes, 1);
    expect(controller.snapshot.attempt.triesRemaining, 2);
    expect(controller.snapshot.wrongFlash, isTrue);
  });

  test('timeout keeps requestId and retries identical physical input', () async {
    final repo = _FakeGame()..firstTimeout = true;
    final store = _MemoryStore();
    final controller = PrufaniGameController(initialAttempt: repo.current,
      gameRepository: repo, economyRepository: _FakeEconomy(),
      pendingStore: store,
      newRequestId: () => '11111111-1111-4111-8111-111111111111');
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.input('А');
    expect(controller.snapshot.pending, isNotNull);
    expect(store.saved, isNotNull);
    expect(controller.snapshot.canType, isFalse);
    await controller.retry();
    expect(repo.requests, 2);
    expect(repo.ids[0], repo.ids[1]);
    expect(store.saved, isNull);
    expect(controller.snapshot.pending, isNull);
  });

  test('hint reveals only selected physical cell', () async {
    final repo = _FakeGame();
    final controller = PrufaniGameController(initialAttempt: repo.current,
      gameRepository: repo, economyRepository: _FakeEconomy(),
      pendingStore: _MemoryStore());
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(await controller.revealSelected(), isTrue);
    expect(controller.snapshot.attempt.layout[0].letter, 'А');
    expect(controller.snapshot.attempt.layout[1].letter, isNull);
  });

  test('UUIDv4 matches backend validation and keyboard includes hard sign', () {
    expect(generateRequestId(), matches(RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(russianKeyboardRows.join(), contains('Ё'));
    expect(russianKeyboardRows.join(), contains('Ъ'));
    expect(normalizedKeyboardLetter('ё'), 'Ё');
    expect(normalizedKeyboardLetter('ZZ'), isNull);
  });
}
