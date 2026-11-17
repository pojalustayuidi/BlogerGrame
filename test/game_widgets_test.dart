import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/presentation/game_widgets.dart';
import 'package:blogergrame/features/game/presentation/game_screen.dart';

void main() {
  testWidgets('board preserves number under each independent tile',
      (tester) async {
    final cells = <PuzzleCell>[
      const PuzzleCell(position: 0, type: 'letter', number: 4),
      const PuzzleCell(position: 1, type: 'letter', number: 4, given: 'А'),
      const PuzzleCell(position: 2, type: 'separator', separator: ' '),
      for (var i = 3; i < 40; i++)
        PuzzleCell(position: i, type: 'letter', number: i % 12 + 1),
    ];
    final attempt = PuzzleAttempt(
        id: 'a',
        levelId: 'l',
        category: 'streamers',
        levelNumber: 1,
        status: 'in_progress',
        mistakes: 0,
        triesRemaining: 3,
        triesPerLife: 3,
        layout: cells,
        notes: const [],
        bonusOptions: const [],
        bonusAnswered: false);
    int? clicked;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 312,
                    child: PrufaniCipherBoard(
                        attempt: attempt,
                        selectedPosition: 0,
                        onSelect: (position) => clicked = position))))));
    expect(find.byKey(const ValueKey('cipher-cell-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cipher-cell-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cipher-cell-0')));
    expect(clicked, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian keyboard contains Ё and Ъ and sends tapped letter',
      (tester) async {
    String? pressed;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PrufaniKeyboard(
                enabled: true, onKey: (letter) => pressed = letter))));
    await tester.tap(find.byKey(const ValueKey('keyboard-Ё')));
    expect(pressed, 'Ё');
    expect(find.byKey(const ValueKey('keyboard-Ъ')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('key colors reflect partial and completed server-confirmed cells',
      (tester) async {
    final attempt = PuzzleAttempt(
        id: 'a',
        levelId: 'l',
        category: 'streamers',
        levelNumber: 1,
        status: 'in_progress',
        mistakes: 0,
        triesRemaining: 3,
        triesPerLife: 3,
        layout: const [
          PuzzleCell(position: 0, type: 'letter', number: 2, given: 'А'),
          PuzzleCell(position: 1, type: 'letter', number: 2),
          PuzzleCell(position: 2, type: 'letter', number: 4, letter: 'Б'),
        ],
        notes: const [],
        bonusOptions: const [],
        bonusAnswered: false);
    String? pressed;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: PrufaniKeyboard(
          attempt: attempt, enabled: true, onKey: (letter) => pressed = letter),
    )));
    await tester.tap(find.byKey(const ValueKey('keyboard-А')));
    expect(pressed, 'А'); // Partial letters may be used for another cell.
    pressed = null;
    await tester.tap(find.byKey(const ValueKey('keyboard-Б')));
    expect(pressed, isNull); // Completed letter is no longer needed.
    await tester.tap(find.byKey(const ValueKey('keyboard-В')));
    expect(pressed, 'В'); // Unknown letters remain available.
    expect(tester.takeException(), isNull);
  });

  testWidgets('long puzzle scrolls with right indicator in a fixed viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final attempt = PuzzleAttempt(
        id: 'a',
        levelId: 'l',
        category: 'streamers',
        levelNumber: 1,
        status: 'in_progress',
        mistakes: 0,
        triesRemaining: 3,
        triesPerLife: 3,
        layout: List.generate(100,
            (i) => PuzzleCell(position: i, type: 'letter', number: i % 12 + 1)),
        notes: const [],
        bonusOptions: const [],
        bonusAnswered: false);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
          width: 310,
          height: 220,
          child: PrufaniBoardViewport(
              attempt: attempt, selectedPosition: 0, onSelect: (_) {})),
    ))));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('game-board-scroll-thumb')), findsOneWidget);
    expect(find.byKey(const ValueKey('game-board-scroll')), findsOneWidget);
    final scrollFinder = find.descendant(
      of: find.byKey(const ValueKey('game-board-scroll')),
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(scrollFinder);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
        find.byKey(const ValueKey('game-board-scroll')), const Offset(0, -280));
    await tester.pump();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

// Additional tests live below the initial suite. They use the server's
// physical-cell layout, not the legacy full-quote/answer map.
