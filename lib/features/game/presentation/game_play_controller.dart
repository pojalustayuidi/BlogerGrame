import 'dart:math';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../../../core/network/backend_exception.dart';
import '../../economy/domain/economy_models.dart';
import '../../economy/domain/economy_repository.dart';
import '../domain/game_models.dart';
import '../domain/game_repository.dart';
import 'game_pending_store.dart';
import 'game_ui_logic.dart';
import 'game_feedback.dart';

const Object _unchanged = Object();

class GamePlayState {
  final PuzzleAttempt attempt;
  final GameWallet? wallet;
  final int? selectedPosition;
  final PendingLetterRequest? pending;
  final bool busy;
  final bool initializing;
  final bool wrongFlash;
  final int? feedbackPosition;
  final String? feedbackLetter;
  final int earnedCoins;
  final String? message;
  final bool isError;

  const GamePlayState({
    required this.attempt,
    required this.selectedPosition,
    this.wallet,
    this.pending,
    this.busy = false,
    this.initializing = true,
    this.wrongFlash = false,
    this.feedbackPosition,
    this.feedbackLetter,
    this.earnedCoins = 0,
    this.message,
    this.isError = false,
  });

  bool get canType =>
      !busy &&
      !initializing &&
      (wallet != null && wallet!.lives > 0) &&
      pending == null &&
      attempt.status == 'in_progress' &&
      selectedCell(attempt, selectedPosition) != null &&
      canEditCell(selectedCell(attempt, selectedPosition)!);

  bool get isSolved => attempt.status == 'solved';
  bool get roundEnded => attempt.status == 'abandoned';
  bool get canLeave => !busy && !initializing && pending == null;

  GamePlayState copyWith({
    PuzzleAttempt? attempt,
    Object? wallet = _unchanged,
    Object? selectedPosition = _unchanged,
    Object? pending = _unchanged,
    bool? busy,
    bool? initializing,
    bool? wrongFlash,
    Object? feedbackPosition = _unchanged,
    Object? feedbackLetter = _unchanged,
    int? earnedCoins,
    Object? message = _unchanged,
    bool? isError,
  }) =>
      GamePlayState(
        attempt: attempt ?? this.attempt,
        wallet:
            identical(wallet, _unchanged) ? this.wallet : wallet as GameWallet?,
        selectedPosition: identical(selectedPosition, _unchanged)
            ? this.selectedPosition
            : selectedPosition as int?,
        pending: identical(pending, _unchanged)
            ? this.pending
            : pending as PendingLetterRequest?,
        busy: busy ?? this.busy,
        initializing: initializing ?? this.initializing,
        wrongFlash: wrongFlash ?? this.wrongFlash,
        feedbackPosition: identical(feedbackPosition, _unchanged)
            ? this.feedbackPosition
            : feedbackPosition as int?,
        feedbackLetter: identical(feedbackLetter, _unchanged)
            ? this.feedbackLetter
            : feedbackLetter as String?,
        earnedCoins: earnedCoins ?? this.earnedCoins,
        message:
            identical(message, _unchanged) ? this.message : message as String?,
        isError: isError ?? this.isError,
      );
}

/// Does not own the guest identity or the backend Dio instance. The server is
/// authoritative for correctness, mistakes, lives, hints and rewards.
class PrufaniGameController extends StateNotifier<GamePlayState> {
  PrufaniGameController({
    required PuzzleAttempt initialAttempt,
    required GameRepository gameRepository,
    required EconomyRepository economyRepository,
    required PendingLetterStore pendingStore,
    String Function()? newRequestId,
    PrufaniGameFeedback? feedback,
  })  : _game = gameRepository,
        _feedback = feedback ?? const PrufaniGameFeedback(),
        _economy = economyRepository,
        _store = pendingStore,
        _newRequestId = newRequestId ?? generateRequestId,
        super(GamePlayState(
          attempt: initialAttempt,
          selectedPosition: firstEditablePosition(initialAttempt),
        ));

  GamePlayState get snapshot => state;

  final GameRepository _game;
  final PrufaniGameFeedback _feedback;
  final EconomyRepository _economy;
  final PendingLetterStore _store;
  final String Function() _newRequestId;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _clearFeedback() {
    _feedbackTimer?.cancel();
    if (!mounted) return;
    state = state.copyWith(
        feedbackPosition: null, feedbackLetter: null, wrongFlash: false);
  }

  void _scheduleFeedbackClear() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 560), _clearFeedback);
  }

  /// Backend charges one life atomically; no navigation on an unknown response.
  Future<bool> forfeit() async {
    if (!mounted || !state.canLeave) return false;
    if (state.attempt.status != 'in_progress') return true;
    state = state.copyWith(busy: true, message: null);
    try {
      final game = _game;
      if (game is! ForfeitableGameRepository) {
        throw UnsupportedError('Backend Patch 08 is required for exit.');
      }
      final result = await (game as ForfeitableGameRepository)
          .abandonAttempt(state.attempt.id);
      if (!mounted) return false;
      state = state.copyWith(wallet: result.wallet, busy: false);
      return result.abandoned;
    } catch (error) {
      if (mounted)
        state = state.copyWith(
            busy: false, message: 'Не удалось выйти: $error', isError: true);
      return false;
    }
  }

  Future<PuzzleAttempt?> restart() async {
    if (!mounted || !state.canLeave || state.attempt.status != 'abandoned')
      return null;
    state = state.copyWith(busy: true, message: null);
    try {
      final wallet = await _economy.wallet();
      if (!mounted) return null;
      if (wallet.lives <= 0) {
        state = state.copyWith(
            busy: false,
            wallet: wallet,
            message: 'Жизни закончились. Дождись восстановления.',
            isError: true);
        return null;
      }
      final attempt = await _game.startOrResume(state.attempt.levelId);
      if (mounted) state = state.copyWith(busy: false, wallet: wallet);
      return attempt;
    } catch (error) {
      if (mounted)
        state = state.copyWith(
            busy: false,
            message: 'Не удалось начать заново: $error',
            isError: true);
      return null;
    }
  }

  /// Current MVP skips the optional author quiz and displays server reveal.
  Future<void> finishWithoutBonus() async {
    if (!mounted ||
        !state.canLeave ||
        !state.isSolved ||
        state.attempt.reveal != null) return;
    state = state.copyWith(busy: true, message: null);
    try {
      if (!state.attempt.bonusAnswered) {
        try {
          await _game.answerBonus(
              attemptId: state.attempt.id, guessedCreatorId: null);
        } on BackendException catch (error) {
          if (error.code != 'BONUS_ALREADY_ANSWERED') rethrow;
        }
      }
      final fresh = await _game.getAttempt(state.attempt.id);
      if (mounted) state = state.copyWith(busy: false, attempt: fresh);
    } catch (error) {
      if (mounted)
        state = state.copyWith(
            busy: false,
            message: 'Не удалось завершить: $error',
            isError: true);
    }
  }

  Future<void> initialize() async {
    if (!mounted) return;
    try {
      final pending = await _store.read(state.attempt.id);
      if (!mounted) return;
      state = state.copyWith(pending: pending);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        initializing: false,
        message: 'Не удалось прочитать локальный запрос: $error',
        isError: true,
      );
      return;
    }
    await refresh();
  }

  void select(int position) {
    if (!mounted || state.busy || state.pending != null) return;
    final cell = selectedCell(state.attempt, position);
    if (cell == null || !canEditCell(cell)) return;
    unawaited(_feedback.selectedCell());
    state = state.copyWith(
      selectedPosition: position,
      message: null,
      wrongFlash: false,
      feedbackLetter: null,
      feedbackPosition: null,
      isError: false,
    );
  }

  Future<void> refresh() async {
    if (!mounted || state.busy) return;
    state = state.copyWith(busy: true, message: null, wrongFlash: false);
    try {
      final fresh = await _game.getAttempt(state.attempt.id);
      if (!mounted) return;
      final pending = state.pending;
      // A confirmed cell or a solved puzzle proves that the old request was
      // processed; otherwise keep the idempotency key for an exact retry.
      final processed = pending != null &&
          (fresh.status != 'in_progress' ||
              (selectedCell(fresh, pending.position)?.isFilled ?? false));
      if (processed) await _store.clear(fresh.id);
      if (!mounted) return;
      final selected = selectedCell(fresh, state.selectedPosition);
      state = state.copyWith(
        attempt: fresh,
        selectedPosition: selected != null && canEditCell(selected)
            ? selected.position
            : firstEditablePosition(fresh),
        pending: processed ? null : pending,
        busy: false,
        initializing: false,
      );
      await _reloadWallet();
      // This MVP has no author quiz, so finish the optional step automatically.
      if (mounted && state.isSolved && state.attempt.reveal == null) {
        await finishWithoutBonus();
      }
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busy: false,
        initializing: false,
        message: 'Не удалось синхронизировать игру: $error',
        isError: true,
      );
    }
  }

  Future<void> _reloadWallet() async {
    try {
      final fresh = await _economy.wallet();
      if (mounted) state = state.copyWith(wallet: fresh);
    } catch (_) {
      // Wallet data are optional to show the board, never invent values.
    }
  }

  Future<void> input(String rawLetter) async {
    if (!mounted || !state.canType) return;
    final letter = normalizedKeyboardLetter(rawLetter);
    if (letter == null) return;
    final position = state.selectedPosition!;
    final command = PendingLetterRequest(
      attemptId: state.attempt.id,
      position: position,
      letter: letter,
      requestId: _newRequestId(),
    );
    _feedbackTimer?.cancel();
    unawaited(_feedback.tappedLetter());
    state = state.copyWith(
        busy: true,
        message: null,
        isError: false,
        feedbackPosition: position,
        feedbackLetter: letter,
        wrongFlash: false);
    try {
      // Durably save BEFORE sending. A connection loss cannot create a new
      // requestId for the same physical keystroke when the user retries.
      await _store.save(command);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          busy: false,
          message: 'Не удалось сохранить ввод перед отправкой: $error',
          isError: true,
        );
      }
      return;
    }
    if (!mounted) return;
    state = state.copyWith(pending: command, busy: false);
    await _sendPending(command);
  }

  Future<void> retry() async {
    if (!mounted || state.busy) return;
    final pending = state.pending;
    if (pending != null) {
      await _sendPending(pending);
    } else {
      await refresh();
    }
  }

  Future<void> _sendPending(PendingLetterRequest command) async {
    if (!mounted || state.busy) return;
    state = state.copyWith(
        busy: true, message: null, isError: false, wrongFlash: false);
    LetterResult result;
    try {
      result = await _game.submitLetter(
        attemptId: command.attemptId,
        position: command.position,
        letter: command.letter,
        requestId: command.requestId,
      );
    } catch (error) {
      if (!mounted) return;
      // These responses guarantee the request was rejected before a letter
      // operation was committed. No need to keep a pending retry for them.
      final rejected = error is BackendException &&
          const {
            'NO_LIVES',
            'CELL_LOCKED',
            'CELL_ALREADY_CORRECT',
            'ATTEMPT_NOT_ACTIVE'
          }.contains(error.code);
      if (rejected) {
        try {
          await _store.clear(command.attemptId);
        } catch (_) {}
        if (!mounted) return;
        state = state.copyWith(
            pending: null,
            busy: false,
            feedbackPosition: null,
            feedbackLetter: null);
        await refresh();
        if (mounted)
          state = state.copyWith(
            message: error is BackendException && error.code == 'NO_LIVES'
                ? 'Жизни закончились. Дождись восстановления или открой магазин.'
                : 'Клетка больше недоступна. Поле обновлено.',
            isError: true,
          );
      } else {
        state = state.copyWith(
          busy: false,
          message: 'Ответ сервера неизвестен. Повтори тот же запрос, чтобы '
              'не потерять лишнюю попытку: $error',
          isError: true,
        );
      }
      return; // On a network failure keep the same requestId in storage.
    }

    // A definitive response means the stored operation is settled, regardless
    // of whether a later GET fails.
    try {
      await _store.clear(command.attemptId);
    } catch (_) {
      // Replaying the same requestId is safe if SharedPreferences fails here.
    }
    if (!mounted) return;
    if (result.correct) {
      unawaited(_feedback.confirmedLetter());
    } else {
      unawaited(_feedback.rejectedLetter(lostLife: result.lostLife));
    }
    state = state.copyWith(
      pending: null,
      wallet: result.wallet ?? state.wallet,
      earnedCoins:
          result.rewardCoins > 0 ? result.rewardCoins : state.earnedCoins,
      // Keep the visual letter until a fresh server board replaces it.
      feedbackPosition: command.position,
      feedbackLetter: command.letter,
      message: result.correct
          ? null
          : result.lostLife
              ? 'Третья ошибка — потеряна одна жизнь.'
              : 'Неверная буква. Осталось попыток: ${result.triesRemaining}.',
      wrongFlash: !result.correct,
      isError: !result.correct,
    );

    try {
      final fresh = await _game.getAttempt(command.attemptId);
      if (!mounted) return;
      state = state.copyWith(
        attempt: fresh,
        feedbackPosition: result.correct ? null : command.position,
        feedbackLetter: result.correct ? null : command.letter,
        selectedPosition: result.correct
            ? nextEditablePosition(fresh, command.position)
            : command.position,
        busy: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        busy: false,
        message: 'Ответ принят сервером. Обнови поле: $error',
        isError: true,
      );
    }
    if (!result.correct) _scheduleFeedbackClear();
    await _reloadWallet();
    if (mounted && state.isSolved && state.attempt.reveal == null) {
      await finishWithoutBonus();
    }
  }

  Future<bool> revealSelected() async {
    if (!mounted || !state.canType) return false;
    final position = state.selectedPosition!;
    state = state.copyWith(busy: true, message: null, isError: false);
    try {
      final result = await _game.revealHint(
        attemptId: state.attempt.id,
        position: position,
      );
      if (!mounted) return false;
      final fresh = await _game.getAttempt(state.attempt.id);
      if (!mounted) return false;
      unawaited(_feedback.revealedHint());
      state = state.copyWith(
        attempt: fresh,
        wallet: result.wallet ?? state.wallet,
        selectedPosition: nextEditablePosition(fresh, position),
        busy: false,
        wrongFlash: false,
        message: 'Буква открыта подсказкой.',
      );
      await _reloadWallet();
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
          busy: false,
          message:
              'Не удалось подтвердить подсказку. Обнови поле перед новым действием: $error',
          isError: true);
      return false;
    }
  }

  Future<bool> saveNote({
    required int number,
    required String? letter,
    required String comment,
  }) async {
    if (!mounted || state.busy) return false;
    state = state.copyWith(busy: true, message: null, isError: false);
    try {
      await _game.saveNote(
        attemptId: state.attempt.id,
        number: number,
        letter: letter,
        comment: comment,
      );
      final fresh = await _game.getAttempt(state.attempt.id);
      if (!mounted) return false;
      state = state.copyWith(
          attempt: fresh, busy: false, message: 'Запись в блокноте сохранена.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
          busy: false,
          isError: true,
          message: 'Не получилось сохранить заметку: $error');
      return false;
    }
  }
}

/// UUIDv4 without adding a new dependency.
String generateRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final prufaniGameProvider = StateNotifierProvider.autoDispose
    .family<PrufaniGameController, GamePlayState, PuzzleAttempt>(
        (ref, attempt) {
  final controller = PrufaniGameController(
    initialAttempt: attempt,
    gameRepository: ref.read(gameRepositoryProvider),
    economyRepository: ref.read(economyRepositoryProvider),
    pendingStore: PendingLetterStore(),
  );
  Future<void>.microtask(controller.initialize);
  return controller;
});
