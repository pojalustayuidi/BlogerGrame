import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/presentation/game_widgets.dart';

void main() {
  testWidgets('Selecting 14 must not highlight other 14 cells', (tester) async {
    final attempt = PuzzleAttempt(
      id: 'test-attempt',
      levelId: 'test-level',
      category: 'streamers',
      levelNumber: 1,
      status: 'in_progress',
      mistakes: 0,
      triesRemaining: 3,
      triesPerLife: 3,
      layout: const [
        PuzzleCell(position: 0, type: 'letter', number: 14),
        PuzzleCell(position: 1, type: 'letter', number: 14),
        PuzzleCell(position: 2, type: 'letter', number: 2),
      ],
      notes: const [],
      bonusOptions: const [],
      bonusAnswered: false,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 370,
          child: PrufaniCipherBoard(
            attempt: attempt,
            selectedPosition: 0,
            onSelect: (_) {},
          ),
        ),
      ),
    ));

    BoxDecoration decorationOf(int position) {
      final cell = find.byKey(ValueKey('cipher-cell-$position'));
      final container = find.descendant(
        of: cell,
        matching: find.byType(AnimatedContainer),
      );
      return tester.widget<AnimatedContainer>(container).decoration!
          as BoxDecoration;
    }

    // Purple marks only the explicitly selected cell.
    expect(decorationOf(0).color, const Color(0xFF8558E0));
    // Other positions remain neutral even when they use the same number.
    expect(decorationOf(1).color, Colors.white);
    expect(decorationOf(2).color, Colors.white);
    expect(find.text('14'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
