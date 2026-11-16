import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../domain/catalog_models.dart';

/// UI projection of the server catalogue. A category's count and completion
/// both come from GET /levels, not from an inferred or hardcoded progression.
class PrufaniCategoryProgress {
  final GameCategory category;
  final List<LevelSummary> levels;

  const PrufaniCategoryProgress(this.category, this.levels);

  int get total => levels.length;
  int get completed => levels.where((level) => level.completed).length;
  double get fraction => total == 0 ? 0 : completed / total;
  int get percent => (fraction * 100).round();
  bool get isEmpty => total == 0;
}

final catalogLevelsProvider = FutureProvider.family<List<LevelSummary>, String>(
  (ref, slug) => ref.watch(catalogRepositoryProvider).levels(category: slug),
);

final catalogCategoriesProvider = FutureProvider<List<PrufaniCategoryProgress>>(
  (ref) async {
    final repository = ref.watch(catalogRepositoryProvider);
    final categories = await repository.categories();
    // List queries run concurrently and remain independent of home selection.
    return Future.wait(categories.map((category) async {
      final levels = await repository.levels(category: category.slug);
      return PrufaniCategoryProgress(category, levels);
    }));
  },
);
