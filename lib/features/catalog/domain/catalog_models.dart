/// Immutable domain objects. No Dio, JSON or Flutter imports.
class GameCategory {
  final String slug;
  final String title;
  final int levels;

  const GameCategory({required this.slug, required this.title, required this.levels});
}

class LevelSummary {
  final String id;
  final String category;
  final int number;
  final int letters;
  final String difficulty;
  final bool completed;
  final bool preview;

  const LevelSummary({
    required this.id,
    required this.category,
    required this.number,
    required this.letters,
    required this.difficulty,
    required this.completed,
    required this.preview,
  });
}
