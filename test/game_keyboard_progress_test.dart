import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/presentation/game_ui_logic.dart';

PuzzleAttempt attemptWith(List<PuzzleCell> cells) => PuzzleAttempt(
      id: 'attempt',
      levelId: 'level',
      category: 'streamers',
      levelNumber: 1,
      status: 'in_progress',
      mistakes: 1,
      triesRemaining: 2,
      triesPerLife: 3,
      layout: cells,
      notes: const [],
      bonusOptions: const [],
      bonusAnswered: false,
    );

void main() {
  test('confirmed letter is partial until all cells of its number are filled', () {
    final attempt = attemptWith(const [
      PuzzleCell(position: 0, type: 'letter', number: 9, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 9),
      PuzzleCell(position: 2, type: 'letter', number: 7, letter: 'Б'),
      PuzzleCell(position: 3, type: 'separator', separator: ' '),
    ]);
    final progress = keyboardProgress(attempt);
    expect(progress['А'], PrufaniKeyProgress.partial);
    expect(progress['Б'], PrufaniKeyProgress.completed);
    expect(progress['В'], isNull);
  });

  test('completion is counted per physical cell, including hinted cells', () {
    final attempt = attemptWith(const [
      PuzzleCell(position: 0, type: 'letter', number: 9, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 9, letter: 'А', hinted: true),
      PuzzleCell(position: 2, type: 'letter', number: 7),
    ]);
    expect(keyboardProgress(attempt)['А'], PrufaniKeyProgress.completed);
    // Hidden letters cannot be inferred from an unsolved cipher number.
    expect(keyboardProgress(attempt)['Б'], isNull);
  });

  test('never treats two same-number cells as auto-filled', () {
    final attempt = attemptWith(const [
      PuzzleCell(position: 0, type: 'letter', number: 14, letter: 'Ё'),
      PuzzleCell(position: 3, type: 'letter', number: 14),
    ]);
    expect(keyboardProgress(attempt)['Ё'], PrufaniKeyProgress.partial);
  });

  test('truly empty puzzle has no exposed keyboard answers', () {
    final attempt = attemptWith(const [
      PuzzleCell(position: 0, type: 'letter', number: 12),
      PuzzleCell(position: 1, type: 'letter', number: 9),
    ]);
    expect(keyboardProgress(attempt), isEmpty);
  });
}
