import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blogergrame/core/di/backend_providers.dart';
import 'package:blogergrame/features/catalog/domain/catalog_models.dart';
import 'package:blogergrame/features/catalog/presentation/catalog_providers.dart';
import 'package:blogergrame/features/catalog/presentation/catalog_screens.dart';
import 'package:blogergrame/features/economy/domain/economy_models.dart';
import 'package:blogergrame/features/economy/domain/economy_repository.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';
import 'package:blogergrame/features/game/presentation/game_screen.dart';
import 'package:blogergrame/features/home/domain/home_overview.dart';
import 'package:blogergrame/features/home/presentation/home_providers.dart';
import 'package:blogergrame/features/home/presentation/home_screen.dart';
import 'package:blogergrame/features/home/presentation/home_widgets.dart';
import 'package:blogergrame/screens/loading_screen/loading_screen.dart';

/// Widget tests run with a test asset bundle, which may not contain the
/// newly-added Prufani PNG/SVG files after a pubspec change. Load the actual
/// checked-in assets from the project directory rather than mocking their
/// contents or suppressing image exceptions.
///
/// This bundle is used by widget tests only, never by production code.
class _ProjectAssetTestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/')) {
      final file = File(key);
      if (file.existsSync()) {
        return SynchronousFuture<ByteData>(
          ByteData.sublistView(file.readAsBytesSync()),
        );
      }
    }
    // Flutter supplies its own AssetManifest.bin, fonts and test runtime data.
    return rootBundle.load(key);
  }
}

/// Provide the assets above MaterialApp / ProviderScope so all descendants,
/// including Image.asset and SvgPicture.asset, resolve against the same bundle.
Widget _withRealAssets(Widget app) => DefaultAssetBundle(
      bundle: _ProjectAssetTestBundle(),
      child: app,
    );

const _categories = [
  GameCategory(
    slug: 'streamers',
    title: 'Стримеры',
    levels: 2,
  )
];

const _levels = [
  LevelSummary(
      id: 'level-1',
      category: 'streamers',
      number: 1,
      letters: 30,
      difficulty: 'easy',
      completed: false,
      preview: true),
  LevelSummary(
      id: 'level-2',
      category: 'streamers',
      number: 2,
      letters: 50,
      difficulty: 'easy',
      completed: false,
      preview: true),
];

GameWallet _wallet(int lives) => GameWallet(
      coins: 123456789,
      lives: lives,
      hints: 8,
      maxLives: 5,
      maxHints: 10,
      lifeRegenMinutes: 30,
      nextLifeAt:
          lives == 5 ? null : DateTime.now().add(const Duration(minutes: 18)),
    );

Widget _levelsApp({
  required Future<List<LevelSummary>> Function() loadLevels,
  required Future<HomeOverview> Function() loadHome,
  EconomyRepository? economy,
}) =>
    _withRealAssets(ProviderScope(
      overrides: [
        catalogLevelsProvider('streamers').overrideWith((ref) => loadLevels()),
        homeOverviewProvider.overrideWith((ref) => loadHome()),
        if (economy != null) economyRepositoryProvider.overrideWithValue(economy),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const PrufaniLevelsPage(categorySlug: 'streamers'),
      ),
    ));

class _WalletCheck extends Fake implements EconomyRepository {
  _WalletCheck(this.response);

  final Future<GameWallet> response;
  int calls = 0;

  @override
  Future<GameWallet> wallet() {
    calls++;
    return response;
  }
}

HomeOverview _overview(int lives, List<LevelSummary> levels) => HomeOverview(
      wallet: _wallet(lives),
      categories: _categories,
      category: _categories.first,
      levels: levels,
    );

void main() {
  test('Prufani UI PNG assets are present on disk', () {
    for (final path in [
      'assets/prufani/brand/prufani_logo.png',
      'assets/prufani/backgrounds/cream.png',
      'assets/prufani/icons/resources/coin.png',
      'assets/prufani/icons/resources/heart_full.png',
      'assets/prufani/icons/resources/bulb.png',
      'assets/prufani/icons/features/clapper.png',
      'assets/prufani/icons/categories/streamers.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: 'Missing asset: $path');
    }
  });

  testWidgets('loading error exposes manual retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(_withRealAssets(MaterialApp(
        home: PrufaniLoadingScreen(
      completedStages: 2,
      error: 'NETWORK_ERROR',
      onRetry: () => retried = true,
    ))));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Нет соединения'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, true);
  });

  testWidgets('resources hide regen countdown with full lives', (tester) async {
    await tester.pumpWidget(_withRealAssets(MaterialApp(
        home: Scaffold(
      body: ResourceStrip(
          wallet: _wallet(5), onCoins: () {}, onLives: () {}, onHints: () {}),
    ))));
    expect(find.text('5/5'), findsOneWidget);
    expect(find.textContaining('через '), findsNothing);
  });

  testWidgets('resources show server-based next-life countdown',
      (tester) async {
    await tester.pumpWidget(_withRealAssets(MaterialApp(
        home: Scaffold(
      body: ResourceStrip(
          wallet: _wallet(4), onCoins: () {}, onLives: () {}, onHints: () {}),
    ))));
    expect(find.text('4/5'), findsOneWidget);
    expect(find.textContaining('через '), findsOneWidget);
  });

  testWidgets('scrolling reveals reward banner above fixed navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 650));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final overview = HomeOverview(
      wallet: _wallet(5),
      categories: _categories,
      category: _categories.first,
      levels: _levels,
    );
    await tester.pumpWidget(_withRealAssets(ProviderScope(
      overrides: [homeOverviewProvider.overrideWith((ref) async => overview)],
      child: const MaterialApp(home: PrufaniHomeScreen()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Ачивки'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Выбрать категорию'), findsOneWidget);
    expect(
        find.ancestor(
            of: find.text('Выбрать категорию'),
            matching: find.byType(PrufaniPrimaryButton)),
        findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Больше наград!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation has four destinations without Play',
      (tester) async {
    final choices = <HomeTab>[];
    await tester.pumpWidget(_withRealAssets(MaterialApp(
        home: Scaffold(
      body: PrufaniBottomNavigation(onSelect: choices.add),
    ))));
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Ачивки'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Играть'), findsNothing);
    await tester.tap(find.text('Ачивки'));
    expect(choices, [HomeTab.achievements]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home opens categories even with a saved attempt',
      (tester) async {
    const attempt = PuzzleAttempt(
      id: 'attempt-1',
      levelId: 'level-1',
      category: 'streamers',
      levelNumber: 1,
      status: 'in_progress',
      mistakes: 0,
      triesRemaining: 3,
      triesPerLife: 3,
      layout: [],
      notes: [],
      bonusOptions: [],
      bonusAnswered: false,
    );
    final overview = HomeOverview(
      wallet: _wallet(5),
      categories: _categories,
      category: _categories.first,
      levels: _levels,
      activeAttempt: attempt,
    );
    await tester.pumpWidget(_withRealAssets(ProviderScope(
      overrides: [
        homeOverviewProvider.overrideWith((ref) async => overview),
        catalogCategoriesProvider.overrideWith((ref) async => [
              PrufaniCategoryProgress(_categories.first, _levels),
            ]),
        catalogLevelsProvider('streamers').overrideWith((ref) async => _levels),
      ],
      child: const MaterialApp(home: PrufaniHomeScreen()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('В ПРОЦЕССЕ'), findsOneWidget);
    await tester.tap(find.text('Выбрать категорию'));
    await tester.pumpAndSettle();
    expect(find.byType(PrufaniCategoriesPage), findsOneWidget);
    expect(find.text('Стримеры'), findsWidgets);
    // No level attempt is started automatically when packs are opened.
    expect(find.byType(PrufaniLevelsPage), findsNothing);

    await tester.tap(find.byKey(const ValueKey('streamers')));
    await tester.pumpAndSettle();
    expect(find.byType(PrufaniLevelsPage), findsOneWidget);
    expect(find.text('Продолжить уровень 1'), findsOneWidget);
    expect(find.byType(PrufaniGameScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('levels show loading, then wallet check, then no lives',
      (tester) async {
    final catalog = Completer<List<LevelSummary>>();
    final home = Completer<HomeOverview>();
    await tester.pumpWidget(_levelsApp(
      loadLevels: () => catalog.future,
      loadHome: () => home.future,
    ));
    expect(find.text('Загружаем уровни…'), findsOneWidget);

    catalog.complete(_levels);
    await tester.pumpAndSettle();
    expect(find.text('Проверяем жизни…'), findsOneWidget);

    home.complete(_overview(0, _levels));
    await tester.pumpAndSettle();
    expect(find.text('Нет жизней'), findsOneWidget);
    expect(find.textContaining('Следующая жизнь в '), findsOneWidget);
    expect(find.text('Все уровни пройдены'), findsNothing);
    expect(find.text('Играть · уровень 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the level checks fresh lives before starting', (tester) async {
    final response = Completer<GameWallet>();
    final economy = _WalletCheck(response.future);
    var lives = 5;
    await tester.pumpWidget(_levelsApp(
      loadLevels: () async => _levels,
      loadHome: () async => _overview(lives, _levels),
      economy: economy,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Играть · уровень 1'));
    await tester.pump();
    expect(find.text('Открываем уровень…'), findsOneWidget);
    expect(economy.calls, 1);

    lives = 0;
    response.complete(_wallet(0));
    await tester.pumpAndSettle();

    expect(find.text('Нет жизней'), findsOneWidget);
    expect(find.byType(PrufaniGameScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening the levels reveals the next tile beyond level 20',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 590));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final levels = List.generate(
      28,
      (index) => LevelSummary(
        id: 'level-${index + 1}',
        category: 'streamers',
        number: index + 1,
        letters: 28,
        difficulty: 'easy',
        completed: index < 24,
        preview: false,
      ),
    );
    await tester.pumpWidget(_levelsApp(
      loadLevels: () async => levels,
      loadHome: () async => _overview(5, levels),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Играть · уровень 25'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-25')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
