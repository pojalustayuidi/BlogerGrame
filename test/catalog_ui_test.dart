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

  test('pagination has twenty tiles and handles all boundaries', () {
    final list = List.generate(42, (index) => _level(index + 1));
    expect(levelPageCount(0), 1);
    expect(levelPageCount(20), 1);
    expect(levelPageCount(21), 2);
    expect(levelPageCount(42), 3);
    expect(levelsForPage(list, 0).length, 20);
    expect(levelsForPage(list, 0).last.number, 20);
    expect(levelsForPage(list, 1).first.number, 21);
    expect(levelsForPage(list, 2).length, 2);
    expect(levelsForPage(list, -1), isEmpty);
    expect(levelsForPage(list, 3), isEmpty);
  });

  testWidgets('completed tile shows a check and three gold star motifs',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SizedBox(
        width: 130,
        height: 120,
        child: PrufaniLevelTile(
          level: _level(7, completed: true),
          isActive: false,
          onTap: null,
        ),
      ),
    )));
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('active attempt highlights current level and remains tappable',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SizedBox(
        width: 125,
        height: 110,
        child: PrufaniLevelTile(
          level: _level(3),
          isActive: true,
          onTap: () => taps++,
        ),
      ),
    )));
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    await tester.tap(find.text('3'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('available tile shows a number and three outline stars',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SizedBox(
        width: 100,
        height: 95,
        child: PrufaniLevelTile(
          level: _level(15),
          isActive: false,
          onTap: () {},
        ),
      ),
    )));
    expect(find.text('15'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
