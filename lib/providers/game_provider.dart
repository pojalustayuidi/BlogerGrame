import 'package:blogergrame/providers/player_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api/player_service.dart';
import '../services/models/level.dart';

part 'game_provider.g.dart';

const _selectedIndexSentinel = Object();

class GameState {
  final Level level;
  final List<int> revealed;
  final List<String?> userInput;
  final int? selectedIndex;
  final List<int> incorrectIndices;
  final List<int> correctIndices;
  final List<int> completedNumbers;
  final int errorCount;
  final DateTime startTime;
  final bool isCompleted;
  final bool isLost;

  GameState({
    required this.level,
    required this.revealed,
    required this.userInput,
    required this.selectedIndex,
    required this.incorrectIndices,
    required this.correctIndices,
    required this.completedNumbers,
    required this.errorCount,
    required this.startTime,
    required this.isCompleted,
    required this.isLost,
  });

  GameState copyWith({
    Level? level,
    List<int>? revealed,
    List<String?>? userInput,
    Object? selectedIndex = _selectedIndexSentinel,
    List<int>? incorrectIndices,
    List<int>? correctIndices,
    List<int>? completedNumbers,
    int? errorCount,
    DateTime? startTime,
    bool? isCompleted,
    bool? isLost,
  }) {
    return GameState(
      level: level ?? this.level,
      revealed: revealed ?? this.revealed,
      userInput: userInput ?? this.userInput,
      selectedIndex: selectedIndex == _selectedIndexSentinel
          ? this.selectedIndex
          : selectedIndex as int?,
      incorrectIndices: incorrectIndices ?? this.incorrectIndices,
      correctIndices: correctIndices ?? this.correctIndices,
      completedNumbers: completedNumbers ?? this.completedNumbers,
      errorCount: errorCount ?? this.errorCount,
      startTime: startTime ?? this.startTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isLost: isLost ?? this.isLost,
    );
  }
}

@Riverpod(keepAlive: false)
class Game extends _$Game {
  @override
  GameState build(Level level) {
    return GameState(
      level: level,
      revealed: List<int>.from(level.revealed),
      userInput: List<String?>.filled(level.quote.length, null),
      selectedIndex: null,
      incorrectIndices: [],
      correctIndices: [],
      completedNumbers: [],
      errorCount: 0,
      startTime: DateTime.now(),
      isCompleted: false,
      isLost: false,
    );
  }

  void selectCell(int index) {
    if (state.isCompleted || state.isLost) return;
    if (index < 0 || index >= state.userInput.length) return;

    if (!state.revealed.contains(index) && !state.correctIndices.contains(index)) {
      state = state.copyWith(
        selectedIndex: state.selectedIndex == index ? null : index,
      );
    }
  }

  Future<void> pressLetter(String letter) async {
    if (state.isCompleted || state.isLost) return;
    if (state.selectedIndex == null) return;

    final index = state.selectedIndex!;
    if (index >= state.userInput.length) return;
    if (state.revealed.contains(index) || state.correctIndices.contains(index)) {
      return;
    }

    final correctChar = state.level.quote[index].toLowerCase();
    final letterLower = letter.toLowerCase();

    final newUserInput = List<String?>.from(state.userInput);
    newUserInput[index] = letter;

    if (letterLower != correctChar) {
      final newErrorCount = state.errorCount + 1;
      final newIncorrectIndices = List<int>.from(state.incorrectIndices);

      if (!newIncorrectIndices.contains(index)) {
        newIncorrectIndices.add(index);
      }

      state = state.copyWith(
        userInput: newUserInput,
        incorrectIndices: newIncorrectIndices,
        errorCount: newErrorCount,
      );

      if (newErrorCount >= 5) {
        await _handleLoss();
        return;
      }

      Future.delayed(const Duration(seconds: 1), () {
        if (state.isCompleted || state.isLost) return;
        if (index >= state.userInput.length) return;

        final updatedInput = List<String?>.from(state.userInput);
        updatedInput[index] = null;

        final updatedIncorrect = List<int>.from(state.incorrectIndices)
          ..remove(index);

        state = state.copyWith(
          userInput: updatedInput,
          incorrectIndices: updatedIncorrect,
        );
      });
    } else {
      final newCorrectIndices = List<int>.from(state.correctIndices);
      if (!newCorrectIndices.contains(index)) {
        newCorrectIndices.add(index);
      }

      final newIncorrectIndices = List<int>.from(state.incorrectIndices)
        ..remove(index);

      state = state.copyWith(
        userInput: newUserInput,
        correctIndices: newCorrectIndices,
        incorrectIndices: newIncorrectIndices,
      );

      _updateCompletedNumbers();
      _moveToNextCell();
      await _checkCompletion();
    }
  }

  Future<bool> useHint() async {
    if (state.selectedIndex == null) return false;
    if (state.isCompleted || state.isLost) return false;

    final result = await PlayerService.useHint(
      levelId: state.level.id,
      letterIndex: state.selectedIndex!,
    );

    if (result != null) {
      final newRevealed = List<int>.from(result['revealedIndices']);
      final newUserInput = List<String?>.from(state.userInput);

      for (final index in newRevealed) {
        if (index >= 0 && index < newUserInput.length) {
          newUserInput[index] = state.level.quote[index];
        }
      }

      state = state.copyWith(
        revealed: newRevealed,
        userInput: newUserInput,
      );

      ref.read(playerProvider.notifier).updateHints(result['hints'] ?? 0);

      _updateCompletedNumbers();
      await _checkCompletion();

      return true;
    }

    return false;
  }

  void _updateCompletedNumbers() {
    final uniqueNumbers = state.level.letterMap.values.toSet();
    final completed = <int>[];

    for (final number in uniqueNumbers) {
      final indices = state.level.quote
          .split('')
          .asMap()
          .entries
          .where(
            (e) => state.level.letterMap[e.value.toLowerCase()] == number,
      )
          .map((e) => e.key)
          .toList();

      final isNumberCompleted = indices.every(
            (index) =>
        state.revealed.contains(index) ||
            (state.userInput[index]?.toLowerCase() ==
                state.level.quote[index].toLowerCase()),
      );

      if (isNumberCompleted) {
        completed.add(number);
      }
    }

    state = state.copyWith(completedNumbers: completed);
  }

  void _moveToNextCell() {
    final currentIndex = state.selectedIndex;
    if (currentIndex == null) return;

    for (int i = currentIndex + 1; i < state.userInput.length; i++) {
      if (!state.revealed.contains(i) && !state.correctIndices.contains(i)) {
        state = state.copyWith(selectedIndex: i);
        return;
      }
    }

    for (int i = 0; i < currentIndex; i++) {
      if (!state.revealed.contains(i) && !state.correctIndices.contains(i)) {
        state = state.copyWith(selectedIndex: i);
        return;
      }
    }

    state = state.copyWith(selectedIndex: null);
  }

  Future<void> _checkCompletion() async {
    if (state.isCompleted || state.isLost) return;

    final phrase = state.level.quote;
    final buffer = StringBuffer();
    final expectedBuffer = StringBuffer();

    for (int i = 0; i < phrase.length; i++) {
      final char = phrase[i];

      if (char == ' ') continue;

      expectedBuffer.write(char.toLowerCase());

      if (state.revealed.contains(i)) {
        buffer.write(char.toLowerCase());
      } else {
        final userChar = state.userInput[i];
        if (userChar == null || userChar.isEmpty) return;
        buffer.write(userChar.toLowerCase());
      }
    }

    if (buffer.toString() == expectedBuffer.toString()) {
      state = state.copyWith(isCompleted: true);

      await PlayerService.updateProgress(
        state.level.id + 1,
        state.level.reward,
      );
    }
  }

  Future<void> _handleLoss() async {
    if (state.isLost || state.isCompleted) return;

    state = state.copyWith(isLost: true);

    final success = await PlayerService.decrementLives();
    if (success) {
      final currentPlayer = ref.read(playerProvider).valueOrNull;
      if (currentPlayer != null) {
        final newLives = (currentPlayer.lives - 1).clamp(0, 5);
        ref.read(playerProvider.notifier).updateLives(newLives);
      }
    }
  }

  void resetLevel() {
    state = GameState(
      level: state.level,
      revealed: List<int>.from(state.level.revealed),
      userInput: List<String?>.filled(state.level.quote.length, null),
      selectedIndex: null,
      incorrectIndices: [],
      correctIndices: [],
      completedNumbers: [],
      errorCount: 0,
      startTime: DateTime.now(),
      isCompleted: false,
      isLost: false,
    );
  }
}