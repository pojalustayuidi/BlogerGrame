import 'package:flutter_test/flutter_test.dart';
import 'package:blogergrame/features/catalog/domain/catalog_models.dart';
import 'package:blogergrame/features/economy/domain/economy_models.dart';
import 'package:blogergrame/features/home/domain/home_overview.dart';
import 'package:blogergrame/features/home/presentation/home_widgets.dart';
import 'package:blogergrame/features/game/domain/game_models.dart';

const categories = [
  GameCategory(slug: 'streamers', title: 'Стримеры', levels: 3),
  GameCategory(slug: 'bloggers', title: 'Блогеры', levels: 1),
];

const wallet = GameWallet(
  coins: 1250,
  lives: 4,
  hints: 3,
  maxLives: 5,
  maxHints: 5,
  lifeRegenMinutes: 30,
  nextLifeAt: null,
);

LevelSummary summary(int number, {bool completed = false}) => LevelSummary(
      id: 'level-$number',
      category: 'streamers',
      number: number,
      letters: 42,
      difficulty: 'easy',
      completed: completed,
      preview: true,
    );

PuzzleAttempt activeAttempt({String status = 'in_progress', String category = 'streamers'}) =>
    PuzzleAttempt(
      id: 'attempt-id',
      levelId: 'level-2',
      category: category,
      levelNumber: 2,
      status: status,
      mistakes: 0,
      triesRemaining: 3,
      triesPerLife: 3,
      layout: const [],
      notes: const [],
      bonusOptions: const [],
      bonusAnswered: false,
    );

void main() {
  test('no stored attempt means Играть, not a fabricated Continue', () {
    final home = HomeOverview(
      wallet: wallet,
      categories: categories,
      category: categories.first,
      levels: [summary(1), summary(2)],
    );
    expect(home.canResume, false);
    expect(home.primaryActionLabel, 'Играть');
    expect(home.displayedLevelNumber, 1);
  });

  test('server-validated matching active attempt means Продолжить', () {
    final home = HomeOverview(
      wallet: wallet,
      categories: categories,
      category: categories.first,
      levels: [summary(1), summary(2)],
      activeAttempt: activeAttempt(),
    );
    expect(home.canResume, true);
    expect(home.primaryActionLabel, 'Продолжить');
    expect(home.displayedLevelNumber, 2);
  });

  test('solved or other-category attempt never shows Продолжить', () {
    HomeOverview withAttempt(PuzzleAttempt attempt) => HomeOverview(
      wallet: wallet,
      categories: categories,
      category: categories.first,
      levels: [summary(1), summary(2)],
      activeAttempt: attempt,
    );
    expect(withAttempt(activeAttempt(status: 'solved')).canResume, false);
    expect(withAttempt(activeAttempt(category: 'bloggers')).canResume, false);
  });

  test('no regen timer at full lives', () {
    final full = GameWallet(
      coins: 20, lives: 5, hints: 0, maxLives: 5,
      maxHints: 5, lifeRegenMinutes: 30,
      nextLifeAt: DateTime(2026, 1, 1),
    );
    expect(lifeCountdown(full, DateTime(2026)), isEmpty);
  });

  test('home progress uses actual completed levels', () {
    final home = HomeOverview(
      wallet: wallet,
      categories: categories,
      category: categories.first,
      levels: [summary(1, completed: true), summary(2), summary(3)],
    );
    expect(home.completedCount, 1);
    expect(home.totalCount, 3);
    expect(home.remainingCount, 2);
    expect(home.progressPercent, 33);
    expect(home.nextLevel?.number, 2);
    expect(home.categoryFinished, false);
  });

  test('empty catalog never pretends there is a playable level', () {
    final home = HomeOverview(
      wallet: wallet,
      categories: const [],
      category: null,
      levels: const [],
    );
    expect(home.nextLevel, null);
    expect(home.progressPercent, 0);
    expect(home.categoryFinished, false);
    expect(HomeOverview.resolveCategory(const [], 'streamers'), null);
  });

  test('completed catalog has no pending level', () {
    final home = HomeOverview(
      wallet: wallet,
      categories: categories,
      category: categories.first,
      levels: [summary(2, completed: true), summary(1, completed: true)],
    );
    expect(home.nextLevel, null);
    expect(home.progressPercent, 100);
    expect(home.categoryFinished, true);
  });

  test('category selection falls back to streamers only when available', () {
    expect(HomeOverview.resolveCategory(categories, 'bloggers')?.slug, 'bloggers');
    expect(HomeOverview.resolveCategory(categories, 'missing')?.slug, 'streamers');
    expect(
      HomeOverview.resolveCategory(const [
        GameCategory(slug: 'tiktokers', title: 'Тиктокеры', levels: 2),
      ], 'streamers')?.slug,
      'tiktokers',
    );
  });

  test('money formatting and server deadline countdown', () {
    expect(formatCoins(1250), '1 250');
    expect(formatCoins(1000000), '1 000 000');
    expect(lifeCountdown(wallet, DateTime(2026)), 'Ожидание');
    final timer = GameWallet(
      coins: 2,
      lives: 4,
      hints: 3,
      maxLives: 5,
      maxHints: 5,
      lifeRegenMinutes: 30,
      nextLifeAt: DateTime(2026, 1, 1, 0, 18, 24),
    );
    expect(lifeCountdown(timer, DateTime(2026, 1, 1)), 'через 18:24');
  });
}
