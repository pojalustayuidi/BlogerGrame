import '../../catalog/domain/catalog_models.dart';
import '../../economy/domain/economy_models.dart';
import '../../game/domain/game_models.dart';

/// Home uses only server-confirmed wallet, catalogue and attempt data.
/// An active attempt is never inferred from a merely incomplete level.
class HomeOverview {
  final GameWallet wallet;
  final List<GameCategory> categories;
  final GameCategory? category;
  final List<LevelSummary> levels;
  final PuzzleAttempt? activeAttempt;

  const HomeOverview({
    required this.wallet,
    required this.categories,
    required this.category,
    required this.levels,
    this.activeAttempt,
  });

  int get completedCount => levels.where((level) => level.completed).length;
  int get totalCount => levels.length;
  int get remainingCount => totalCount - completedCount;
  double get completionFraction =>
      totalCount == 0 ? 0 : completedCount / totalCount;
  int get progressPercent => (completionFraction * 100).round();

  LevelSummary? get nextLevel {
    final pending = levels.where((level) => !level.completed).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return pending.isEmpty ? null : pending.first;
  }

  bool get categoryFinished => totalCount > 0 && remainingCount == 0;

  /// Resume is shown only for a persisted attempt validated with GET /attempts/id.
  bool get canResume => activeAttempt != null &&
      activeAttempt!.status == 'in_progress' &&
      activeAttempt!.category == category?.slug;

  int? get displayedLevelNumber =>
      canResume ? activeAttempt!.levelNumber : nextLevel?.number;

  String get primaryActionLabel => canResume ? 'Продолжить' : 'Играть';

  static GameCategory? resolveCategory(
      List<GameCategory> categories, String? preferred) {
    if (categories.isEmpty) return null;
    for (final item in categories) {
      if (item.slug == preferred) return item;
    }
    for (final item in categories) {
      if (item.slug == 'streamers') return item;
    }
    return categories.first;
  }
}
