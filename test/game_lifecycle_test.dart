import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/economy/domain/economy_models.dart';
import 'package:blogergrame/features/economy/domain/economy_repository.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/domain/game_repository.dart';
import 'package:blogergrame/features/game/presentation/game_pending_store.dart';
import 'package:blogergrame/features/game/presentation/game_play_controller.dart';

const testWallet = GameWallet(
    coins: 30,
    lives: 5,
    hints: 2,
    maxLives: 5,
    maxHints: 20,
    lifeRegenMinutes: 30,
    nextLifeAt: null);
const emptyWallet = GameWallet(
    coins: 30,
    lives: 0,
    hints: 2,
    maxLives: 5,
    maxHints: 20,
    lifeRegenMinutes: 30,
    nextLifeAt: null);
PuzzleAttempt attempt([String status = 'in_progress']) => PuzzleAttempt(
    id: 'a',
    levelId: 'l',
    category: 'streamers',
    levelNumber: 1,
    status: status,
    mistakes: status == 'abandoned' ? 3 : 0,
    triesRemaining: status == 'abandoned' ? 0 : 3,
    triesPerLife: 3,
    layout: const [PuzzleCell(position: 0, type: 'letter', number: 1)],
    notes: const [],
    bonusOptions: const [],
    bonusAnswered: false);

class MemoryPending extends PendingLetterStore {
  @override
  Future<PendingLetterRequest?> read(String id) async => null;
  @override
  Future<void> save(PendingLetterRequest data) async {}
  @override
  Future<void> clear(String id) async {}
}

class EconomyFake implements EconomyRepository {
  @override
  Future<GameWallet> wallet() async => testWallet;
  @override
  Future<List<ShopOffer>> shopOffers() async => const [];
  @override
  Future<PurchaseReceipt> buyShopItem(
          {required String sku, required String requestId}) =>
      throw UnimplementedError();
}

class GameFake implements GameRepository, ForfeitableGameRepository {
  GameFake(this.current);
  PuzzleAttempt current;
  int exitCalls = 0;
  @override
  Future<PuzzleAttempt> getAttempt(String id) async => current;
  @override
  Future<PuzzleAttempt> startOrResume(String id) async => attempt();
  @override
  Future<ForfeitResult> abandonAttempt(String id) async {
    exitCalls++;
    current = attempt('abandoned');
    return const ForfeitResult(
        abandoned: true, charged: true, wallet: testWallet);
  }

  @override
  Future<LetterResult> submitLetter(
          {required String attemptId,
          required int position,
          required String letter,
          required String requestId}) =>
      throw UnimplementedError();
  @override
  Future<HintResult> revealHint(
          {required String attemptId, required int position}) =>
      throw UnimplementedError();
  @override
  Future<PuzzleNote> saveNote(
          {required String attemptId,
          required int number,
          required String? letter,
          required String comment}) =>
      throw UnimplementedError();
  @override
  Future<BonusResult> answerBonus(
          {required String attemptId, required String? guessedCreatorId}) =>
      throw UnimplementedError();
}

void main() {
  test('no lives disables keyboard, even with an editable cell', () {
    final state = GamePlayState(
        attempt: attempt(),
        wallet: emptyWallet,
        selectedPosition: 0,
        initializing: false);
    expect(state.canType, false);
  });
  test('forfeit calls backend exactly once and allows navigation after success',
      () async {
    final fake = GameFake(attempt());
    final controller = PrufaniGameController(
        initialAttempt: fake.current,
        gameRepository: fake,
        economyRepository: EconomyFake(),
        pendingStore: MemoryPending());
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.snapshot.canLeave, true);
    expect(await controller.forfeit(), true);
    expect(fake.exitCalls, 1);
  });
  test('restart is available after abandoned round', () async {
    final fake = GameFake(attempt('abandoned'));
    final controller = PrufaniGameController(
        initialAttempt: fake.current,
        gameRepository: fake,
        economyRepository: EconomyFake(),
        pendingStore: MemoryPending());
    addTearDown(controller.dispose);
    await controller.initialize();
    final fresh = await controller.restart();
    expect(fresh?.status, 'in_progress');
  });
}
