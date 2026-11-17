import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/presentation/game_ui_logic.dart';
import 'package:blogergrame/features/game/presentation/game_widgets.dart';

PuzzleAttempt puzzle(List<PuzzleCell> cells) => PuzzleAttempt(
      id: 'demo-attempt',
      levelId: 'demo-level',
      category: 'streamers',
      levelNumber: 1,
      status: 'in_progress',
      mistakes: 0,
      triesRemaining: 3,
      triesPerLife: 3,
      layout: cells,
      notes: const [],
      bonusOptions: const [],
      bonusAnswered: false,
    );

void main() {
  test('all 33 Russian keys are visible in three evenly sized rows', () {
    expect(russianKeyboardRows.map((row) => row.length), [11, 11, 11]);
    final letters = russianKeyboardRows.join();
    expect(letters.length, 33);
    expect(letters.split('').toSet().length, 33);
    expect(letters, contains('Ь'));
    expect(letters, contains('Ъ'));
    expect(letters, contains('Ё'));
    expect(normalizedKeyboardLetter('ь'), 'Ь');
  });

  test('one solved A remains yellow until every A-number cell is filled', () {
    final partial = puzzle(const [
      PuzzleCell(position: 0, type: 'letter', number: 1, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 1),
      PuzzleCell(position: 2, type: 'letter', number: 2),
    ]);
    expect(keyboardProgress(partial)['А'], PrufaniKeyProgress.partial);
    expect(completedCipherNumbers(partial), isEmpty);
    expect(remainingCipherNumberCount(partial), 2);

    final full = puzzle(const [
      PuzzleCell(position: 0, type: 'letter', number: 1, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 1, letter: 'А'),
      PuzzleCell(position: 2, type: 'letter', number: 2),
    ]);
    expect(keyboardProgress(full)['А'], PrufaniKeyProgress.completed);
    expect(completedCipherNumbers(full), {1});
    expect(remainingCipherNumberCount(full), 1);
    // Unknown number 2 must not reveal a secret answer.
    expect(keyboardProgress(full).length, 1);
  });

  testWidgets('soft sign has a readable, working key', (tester) async {
    String? input;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
          width: 370,
          child: PrufaniKeyboard(
            enabled: true,
            onKey: (letter) => input = letter,
          )),
    ))));
    final softSign = find.byKey(const ValueKey('keyboard-Ь'));
    expect(softSign, findsOneWidget);
    await tester.ensureVisible(softSign);
    await tester.tap(softSign);
    expect(input, 'Ь');
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed number disappears, solved letter stays visible',
      (tester) async {
    final incomplete = puzzle(const [
      PuzzleCell(position: 0, type: 'letter', number: 1, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 1),
      PuzzleCell(position: 2, type: 'separator', separator: ' '),
      PuzzleCell(position: 3, type: 'letter', number: 2),
    ]);
    final done = puzzle(const [
      PuzzleCell(position: 0, type: 'letter', number: 1, given: 'А'),
      PuzzleCell(position: 1, type: 'letter', number: 1, letter: 'А'),
      PuzzleCell(position: 2, type: 'separator', separator: ' '),
      PuzzleCell(position: 3, type: 'letter', number: 2),
    ]);
    Widget display(PuzzleAttempt attempt) => MaterialApp(
            home: Scaffold(
          body: SizedBox(
              width: 350,
              child: PrufaniCipherBoard(
                attempt: attempt,
                selectedPosition: 3,
                onSelect: (_) {},
              )),
        ));
    await tester.pumpWidget(display(incomplete));
    expect(find.text('1'), findsNWidgets(2));
    await tester.pumpWidget(display(done));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.text('А'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fully completed soft sign key is green and non-interactive',
      (tester) async {
    var presses = 0;
    final full = puzzle(const [
      PuzzleCell(position: 0, type: 'letter', number: 12, given: 'Ь'),
      PuzzleCell(position: 1, type: 'letter', number: 12, letter: 'Ь'),
    ]);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
          width: 370,
          child: PrufaniKeyboard(
            attempt: full,
            enabled: true,
            onKey: (_) => presses++,
          )),
    ))));
    expect(keyboardProgress(full)['Ь'], PrufaniKeyProgress.completed);
    await tester.tap(find.byKey(const ValueKey('keyboard-Ь')),
        warnIfMissed: false);
    expect(presses, 0);
    expect(tester.takeException(), isNull);
  });
}
