import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blogergrame/features/catalog/domain/catalog_models.dart';
import 'package:blogergrame/features/economy/domain/economy_models.dart';
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
    expect(find.text('Играть'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Больше наград!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
