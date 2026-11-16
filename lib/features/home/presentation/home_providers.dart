import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../../catalog/domain/catalog_models.dart';
import '../data/home_attempt_store.dart';
import '../domain/home_overview.dart';

final selectedHomeCategoryProvider =
    StateProvider<String?>((ref) => 'streamers');

final homeAttemptStoreProvider =
    Provider<HomeAttemptStore>((ref) => HomeAttemptStore());

/// One authoritative home payload; warm it during startup and reuse on home.
final homeOverviewProvider = FutureProvider<HomeOverview>((ref) async {
  final categoryRepository = ref.watch(catalogRepositoryProvider);
  final economyRepository = ref.watch(economyRepositoryProvider);
  final gameRepository = ref.watch(gameRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final activeStore = ref.watch(homeAttemptStoreProvider);
  final selected = ref.watch(selectedHomeCategoryProvider);

  final playerId = await authRepository.getPlayerId();
  final categoriesFuture = categoryRepository.categories();
  final walletFuture = economyRepository.wallet();
  final activeFuture = activeStore.loadValidated(playerId, gameRepository);

  final categories = await categoriesFuture;
  final category = HomeOverview.resolveCategory(categories, selected);
  final Future<List<LevelSummary>> levelsFuture = category == null
      ? Future<List<LevelSummary>>.value(const <LevelSummary>[])
      : categoryRepository.levels(category: category.slug);

  final wallet = await walletFuture;
  final activeAttempt = await activeFuture;
  final levels = await levelsFuture;
  return HomeOverview(
    wallet: wallet,
    categories: categories,
    category: category,
    levels: levels,
    activeAttempt: activeAttempt,
  );
});
