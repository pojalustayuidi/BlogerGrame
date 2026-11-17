import '../domain/catalog_models.dart';

/// Sequential progression until replay/star economy is implemented.
LevelSummary? nextPlayableLevel(Iterable<LevelSummary> levels) {
  LevelSummary? result;
  for (final level in levels) {
    if (level.completed) continue;
    if (result == null || level.number < result.number) result = level;
  }
  return result;
}

bool mayStartLevel(
    {required LevelSummary level,
    required Iterable<LevelSummary> levels,
    required int lives}) {
  final allowed = nextPlayableLevel(levels);
  return lives > 0 && !level.completed && allowed?.id == level.id;
}
