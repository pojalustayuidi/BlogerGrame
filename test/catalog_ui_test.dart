import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/catalog/domain/catalog_models.dart';
import 'package:blogergrame/features/catalog/presentation/catalog_providers.dart';
import 'package:blogergrame/features/catalog/presentation/catalog_widgets.dart';

const _category =
    GameCategory(slug: 'streamers', title: 'Стримеры', levels: 22);

LevelSummary _level(int number, {bool completed = false}) => LevelSummary(
      id: 'level-$number',
      category: 'streamers',
      number: number,
      letters: 28,
      difficulty: 'easy',
      completed: completed,
      preview: false,
    );

void main() {
  test('category totals and progress are derived from actual API levels', () {
    final empty = PrufaniCategoryProgress(_category, const []);
    expect(empty.completed, 0);
    expect(empty.total, 0);
    expect(empty.percent, 0);
    expect(empty.isEmpty, true);

    final partial = PrufaniCategoryProgress(_category, [
      _level(1, completed: true),
      _level(2),
      _level(3, completed: true),
      _level(4),
    ]);
    expect(partial.total, 4);
    expect(partial.completed, 2);
    expect(partial.percent, 50);
  });

  testWidgets('a completed tile shows completion without a star rating',
      (tester) async {
    await tester.pumpWidget(_tile(
      level: _level(7, completed: true),
      status: PrufaniLevelTileStatus.completed,
    ));

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved attempt remains tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_tile(
      level: _level(3),
      status: PrufaniLevelTileStatus.resume,
      onTap: () => taps++,
    ));

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.text('3'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a locked tile is announced as locked', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_tile(
        level: _level(15),
        status: PrufaniLevelTileStatus.locked,
      ));

      expect(find.bySemanticsLabel('Уровень 15, закрыт'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}

Widget _tile({
  required LevelSummary level,
  required PrufaniLevelTileStatus status,
  VoidCallback? onTap,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 58,
          height: 62,
          child: PrufaniLevelTile(level: level, status: status, onTap: onTap),
        ),
      ),
    );
