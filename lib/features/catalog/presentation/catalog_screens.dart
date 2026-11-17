import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../../../core/theme/prufani_theme.dart';
import '../../economy/domain/economy_models.dart';
import '../../game/domain/game_models.dart';
import '../../game/presentation/game_screen.dart';
import '../../home/presentation/home_providers.dart';
import '../../home/presentation/home_sheets.dart';
import '../../home/presentation/home_widgets.dart';
import '../domain/catalog_models.dart';
import 'catalog_access_rules.dart';
import 'catalog_providers.dart';
import 'catalog_widgets.dart';

const _catalogTitleStyle = TextStyle(
  color: PrufaniColors.ink,
  fontSize: 25,
  fontWeight: FontWeight.w900,
  height: 1.15,
);

/// These are the *same* routes as Patch 04, redesigned in-place.
Future<void> openPrufaniCategoriesPage(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PrufaniCategoriesPage(),
    ));

Future<void> openPrufaniLevelsPage(
  BuildContext context, {
  required String categorySlug,
  String? categoryTitle,
}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PrufaniLevelsPage(
        categorySlug: categorySlug,
        categoryTitle: categoryTitle,
      ),
    ));

Future<void> openPrufaniAchievementsPage(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PrufaniAchievementsPage(),
    ));

class PrufaniCategoriesPage extends ConsumerWidget {
  const PrufaniCategoriesPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(catalogCategoriesProvider);
    ref.invalidate(homeOverviewProvider);
    try {
      await ref.read(catalogCategoriesProvider.future);
    } catch (_) {
      // Show the existing retry state; never reset a guest session here.
    }
  }

  Future<void> _onTab(BuildContext context, WidgetRef ref, HomeTab tab) async {
    switch (tab) {
      case HomeTab.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case HomeTab.achievements:
        await openPrufaniAchievementsPage(context);
        return;
      case HomeTab.shop:
        await showPrufaniShop(context, ref);
        return;
      case HomeTab.profile:
        await showPrufaniProfile(context, ref);
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(catalogCategoriesProvider);
    final wallet = ref.watch(homeOverviewProvider).valueOrNull?.wallet;
    return _CatalogScaffold(
      bottomNavigation: PrufaniBottomNavigation(
        // This is a nested game screen, not a fifth main tab.
        selectedTab: null,
        onSelect: (tab) => _onTab(context, ref, tab),
      ),
      child: RefreshIndicator(
        color: PrufaniColors.primary,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _CatalogTopBar(
              wallet: wallet,
              onBack: () => Navigator.of(context).pop(),
              onCoins: () => showPrufaniShop(context, ref),
              onLives:
                  wallet == null ? null : () => showPrufaniLives(context, wallet),
            ),
            const SizedBox(height: 14),
            const Text('Категории', style: _catalogTitleStyle),
            const SizedBox(height: 14),
            packsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const _CatalogLoading(),
              error: (_, __) => _CatalogFailure(
                title: 'Не удалось загрузить категории',
                onRetry: () => _refresh(ref),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _CatalogEmpty('Пока нет доступных категорий.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _packCard(context, ref, item),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _packCard(
    BuildContext context,
    WidgetRef ref,
    PrufaniCategoryProgress progress,
  ) =>
      PrufaniCategoryCard(
        key: ValueKey(progress.category.slug),
        progress: progress,
        onTap: progress.isEmpty
            ? null
            : () async {
                ref.read(selectedHomeCategoryProvider.notifier).state =
                    progress.category.slug;
                await openPrufaniLevelsPage(
                  context,
                  categorySlug: progress.category.slug,
                  categoryTitle: progress.category.title,
                );
                if (context.mounted) {
                  ref.invalidate(catalogCategoriesProvider);
                  ref.invalidate(homeOverviewProvider);
                }
              },
      );
}

class PrufaniLevelsPage extends ConsumerStatefulWidget {
  const PrufaniLevelsPage({
    super.key,
    required this.categorySlug,
    this.categoryTitle,
  });

  final String categorySlug;
  final String? categoryTitle;

  @override
  ConsumerState<PrufaniLevelsPage> createState() => _PrufaniLevelsPageState();
}

class _PrufaniLevelsPageState extends ConsumerState<PrufaniLevelsPage> {
  bool _opening = false;
  final _recommendedTile = GlobalKey();
  bool _revealedRecommendedTile = false;

  Future<void> _refresh() async {
    ref.invalidate(catalogLevelsProvider(widget.categorySlug));
    ref.invalidate(homeOverviewProvider);
    try {
      await ref.read(catalogLevelsProvider(widget.categorySlug).future);
    } catch (_) {
      // Retry/error is rendered by the FutureProvider; keep the stored attempt.
    }
  }

  Future<void> _openLevel(
      LevelSummary level, PuzzleAttempt? knownAttempt) async {
    if (_opening || level.completed) return;
    final available =
        ref.read(catalogLevelsProvider(widget.categorySlug)).valueOrNull;
    if (available == null ||
        !mayStartLevel(level: level, levels: available, lives: 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала пройди предыдущий уровень.')));
      return;
    }
    setState(() => _opening = true);
    try {
      final currentWallet = await ref.read(economyRepositoryProvider).wallet();
      if (!mounted) return;
      if (currentWallet.lives <= 0) {
        ref.invalidate(homeOverviewProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Нет жизней. Дождись восстановления.')));
        return;
      }
      final game = ref.read(gameRepositoryProvider);
      final start = ref.read(startOrResumeAttemptProvider);
      final auth = ref.read(authRepositoryProvider);
      final store = ref.read(homeAttemptStoreProvider);
      final PuzzleAttempt attempt = knownAttempt != null &&
              knownAttempt.levelId == level.id &&
              knownAttempt.status == 'in_progress'
          ? await game.getAttempt(knownAttempt.id)
          : await start(level.id);
      final playerId = await auth.getPlayerId();
      await store.save(playerId, attempt);
      if (!mounted) return;
      ref.invalidate(homeOverviewProvider);
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PrufaniGameScreen(initialAttempt: attempt),
        ),
      );
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Не получилось открыть уровень. Попробуй ещё раз.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Детали',
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Ошибка открытия'),
              content: SelectableText('$error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Закрыть'),
                )
              ],
            ),
          ),
        ),
      ));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _revealRecommendedTile() {
    if (_revealedRecommendedTile) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _revealedRecommendedTile) return;
      final tile = _recommendedTile.currentContext;
      if (tile == null) return;
      _revealedRecommendedTile = true;
      unawaited(Scrollable.ensureVisible(
        tile,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ));
    });
  }

  Widget? _bottomAction({
    required List<LevelSummary>? levels,
    required LevelSummary? nextLevel,
    required PuzzleAttempt? activeAttempt,
    required GameWallet? wallet,
    required bool walletFailed,
  }) {
    if (_opening) {
      return const _LevelBottomAction('Открываем уровень…');
    }
    if (levels == null) {
      return const _LevelBottomAction('Загружаем уровни…');
    }
    if (levels.isEmpty) return null;
    if (nextLevel == null) {
      return const _LevelBottomAction('Все уровни пройдены');
    }
    if (wallet == null) {
      if (walletFailed) {
        return _LevelBottomAction(
          'Повторить',
          detail: 'Не удалось проверить жизни.',
          onTap: _refresh,
        );
      }
      return const _LevelBottomAction('Проверяем жизни…');
    }
    if (wallet.lives <= 0) {
      return _LevelBottomAction(
        'Нет жизней',
        detail: _lifeRecoveryLabel(wallet.nextLifeAt),
      );
    }
    return _LevelBottomAction(
      activeAttempt == null
          ? 'Играть · уровень ${nextLevel.number}'
          : 'Продолжить уровень ${nextLevel.number}',
      onTap: () => _openLevel(nextLevel, activeAttempt),
    );
  }

  String _lifeRecoveryLabel(DateTime? deadline) {
    if (deadline == null) return 'Жизни восстанавливаются автоматически.';
    if (!deadline.isAfter(DateTime.now())) {
      return 'Потяни список вниз, чтобы проверить жизни.';
    }
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(deadline.toLocal()),
      alwaysUse24HourFormat: true,
    );
    return 'Следующая жизнь в $time';
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(catalogLevelsProvider(widget.categorySlug));
    final homeAsync = ref.watch(homeOverviewProvider);
    final wallet = homeAsync.valueOrNull?.wallet;
    final saved = homeAsync.valueOrNull?.activeAttempt;
    final ordered = levelsAsync.valueOrNull?.toList()
      ?..sort((a, b) => a.number.compareTo(b.number));
    final nextLevel = nextPlayableLevel(ordered ?? const []);
    final activeAttempt = saved != null &&
            saved.category == widget.categorySlug &&
            saved.status == 'in_progress' &&
            saved.levelId == nextLevel?.id
        ? saved
        : null;

    return _CatalogScaffold(
      bottomAction: levelsAsync.hasError
          ? null
          : _bottomAction(
              levels: ordered,
              nextLevel: nextLevel,
              activeAttempt: activeAttempt,
              wallet: wallet,
              walletFailed: homeAsync.hasError,
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CatalogTopBar(
              wallet: wallet,
              onBack: () => Navigator.of(context).pop(),
              onCoins: () => showPrufaniShop(context, ref),
              onLives:
                  wallet == null ? null : () => showPrufaniLives(context, wallet),
            ),
            const SizedBox(height: 12),
            _LevelHeader(
              slug: widget.categorySlug,
              title: widget.categoryTitle ?? _categoryTitle(widget.categorySlug),
              completed: ordered?.where((level) => level.completed).length ?? 0,
              total: ordered?.length ?? 0,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: RefreshIndicator(
                color: PrufaniColors.primary,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    levelsAsync.when(
                      skipLoadingOnReload: true,
                      loading: () => const _CatalogLoading(),
                      error: (_, __) => _CatalogFailure(
                        title: 'Не удалось загрузить уровни',
                        onRetry: _refresh,
                      ),
                      data: (data) {
                        if (data.isEmpty) {
                          return const _CatalogEmpty(
                            'В этой категории пока нет уровней.',
                          );
                        }
                        if (nextLevel != null) _revealRecommendedTile();
                        return _LevelBoard(
                          levels: ordered ?? data,
                          recommendedId: nextLevel?.id,
                          recommendedTile: _recommendedTile,
                          resuming: activeAttempt != null,
                          opening: _opening,
                          lives: wallet?.lives,
                          onLevel: (level) => _openLevel(level, activeAttempt),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogScaffold extends StatelessWidget {
  const _CatalogScaffold(
      {required this.child, this.bottomNavigation, this.bottomAction});
  final Widget child;
  final Widget? bottomNavigation;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: PrufaniColors.cream,
          bottomNavigationBar: bottomNavigation == null && bottomAction == null
              ? null
              : SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 3),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: bottomAction ?? bottomNavigation!,
                    ),
                  ),
                ),
          body: Stack(children: [
            Positioned.fill(
                child:
                    Image.asset(PrufaniAssets.background, fit: BoxFit.cover)),
            SafeArea(
                bottom: false,
                child: Center(
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: child,
                ))),
          ]),
        ),
      );
}

/// Compact branded row with only actual economy values from the backend.
class _CatalogTopBar extends StatelessWidget {
  const _CatalogTopBar(
      {required this.wallet,
      required this.onBack,
      required this.onCoins,
      this.onLives});
  final GameWallet? wallet;
  final VoidCallback onBack;
  final VoidCallback onCoins;
  final VoidCallback? onLives;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Row(children: [
          Material(
            color: const Color(0xFFF6ECFF),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(
                  width: 43,
                  height: 47,
                  child: Icon(Icons.arrow_back_rounded,
                      size: 25, color: PrufaniColors.primaryDark)),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
              child: Image.asset(PrufaniAssets.logo,
                  fit: BoxFit.contain, alignment: Alignment.centerLeft)),
          const SizedBox(width: 4),
          _TinyResourcePill(
            icon: PrufaniAssets.coin,
            value: wallet == null ? '—' : formatCoins(wallet!.coins),
            onTap: onCoins,
            width: 99,
          ),
          const SizedBox(width: 5),
          _TinyResourcePill(
            icon: PrufaniAssets.heart,
            value:
                wallet == null ? '—' : '${wallet!.lives}/${wallet!.maxLives}',
            onTap: onLives,
            width: 78,
          ),
        ]),
      );
}

class _TinyResourcePill extends StatelessWidget {
  const _TinyResourcePill(
      {required this.icon,
      required this.value,
      required this.onTap,
      required this.width});
  final String icon;
  final String value;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 43,
        child: Material(
          color: const Color(0xFFF9EDFF),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2CFF4)),
                borderRadius: BorderRadius.circular(22),
                boxShadow: catalogCardShadow,
              ),
              child: Row(children: [
                Image.asset(icon, width: 29, height: 29),
                const SizedBox(width: 2),
                Expanded(
                    child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      maxLines: 1,
                      style: const TextStyle(
                          color: PrufaniColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                )),
              ]),
            ),
          ),
        ),
      );
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.slug,
    required this.title,
    required this.completed,
    required this.total,
  });

  final String slug;
  final String title;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: categorySurface(slug),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xCBFFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
          child: Row(
            children: [
              Image.asset(
                categoryIllustration(slug),
                width: 46,
                height: 46,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _catalogTitleStyle),
                    if (total > 0) ...[
                      const SizedBox(height: 6),
                      PrufaniCatalogProgress(completed: completed, total: total),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LevelBoard extends StatelessWidget {
  const _LevelBoard({
    required this.levels,
    required this.recommendedId,
    required this.recommendedTile,
    required this.resuming,
    required this.opening,
    required this.lives,
    required this.onLevel,
  });

  final List<LevelSummary> levels;
  final String? recommendedId;
  final GlobalKey recommendedTile;
  final bool resuming;
  final bool opening;
  final int? lives;
  final ValueChanged<LevelSummary> onLevel;

  PrufaniLevelTileStatus _status(LevelSummary level) => switch (level) {
        _ when level.completed => PrufaniLevelTileStatus.completed,
        _ when level.id != recommendedId => PrufaniLevelTileStatus.locked,
        _ when lives == null => PrufaniLevelTileStatus.unavailable,
        _ when lives! <= 0 => PrufaniLevelTileStatus.noLives,
        _ when resuming => PrufaniLevelTileStatus.resume,
        _ => PrufaniLevelTileStatus.ready,
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final columns =
              ((constraints.maxWidth + gap) / (52 + gap)).floor().clamp(1, 5);
          final width =
              ((constraints.maxWidth - gap * (columns - 1)) / columns)
                  .floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final level in levels)
                SizedBox(
                  key: level.id == recommendedId ? recommendedTile : null,
                  width: width,
                  height: 62,
                  child: PrufaniLevelTile(
                    key: ValueKey(level.id),
                    level: level,
                    status: _status(level),
                    onTap: !opening &&
                            level.id == recommendedId &&
                            (lives ?? 0) > 0
                        ? () => onLevel(level)
                        : null,
                  ),
                ),
            ],
          );
        },
      );
}

class _LevelBottomAction extends StatelessWidget {
  const _LevelBottomAction(this.label, {this.detail, this.onTap});

  final String label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (detail case final message?) ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: PrufaniColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (onTap != null)
              PrufaniPrimaryButton(label: label, onPressed: onTap)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9F2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PrufaniColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// The backend has no achievements API. Show an honest preview, not fake data.
class PrufaniAchievementsPage extends ConsumerWidget {
  const PrufaniAchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _CatalogScaffold(
        bottomNavigation: PrufaniBottomNavigation(
          selectedTab: HomeTab.achievements,
          onSelect: (tab) async {
            switch (tab) {
              case HomeTab.home:
                Navigator.of(context).popUntil((route) => route.isFirst);
                break;
              case HomeTab.achievements:
                break;
              case HomeTab.shop:
                await showPrufaniShop(context, ref);
                break;
              case HomeTab.profile:
                await showPrufaniProfile(context, ref);
                break;
            }
          },
        ),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          _CatalogTopBar(
            wallet: ref.watch(homeOverviewProvider).asData?.value.wallet,
            onBack: () => Navigator.of(context).pop(),
            onCoins: () => showPrufaniShop(context, ref),
          ),
          const SizedBox(height: 36),
          Image.asset('assets/prufani/icons/features/trophy.png',
              height: 145, width: 145),
          const SizedBox(height: 20),
          const Text('Ачивки',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: PrufaniColors.primaryDark)),
          const SizedBox(height: 8),
          const Text(
              'Награды и достижения появятся здесь после '
              'добавления соответствующей механики.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: PrufaniColors.muted)),
          const SizedBox(height: 14),
          const Center(child: Chip(label: Text('Скоро'))),
        ]),
      );
}

String _categoryTitle(String slug) {
  switch (slug) {
    case 'streamers':
      return 'Стримеры';
    case 'bloggers':
      return 'Блогеры';
    case 'tiktokers':
      return 'Тиктокеры';
    default:
      return 'Уровни';
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
            child: CircularProgressIndicator(color: PrufaniColors.primary)),
      );
}

class _CatalogEmpty extends StatelessWidget {
  const _CatalogEmpty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: PrufaniColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700))),
      );
}

class _CatalogFailure extends StatelessWidget {
  const _CatalogFailure({required this.title, required this.onRetry});
  final String title;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PrufaniColors.lavender,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded,
              size: 35, color: PrufaniColors.primaryDark),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PrufaniColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 12),
          PrufaniPrimaryButton(label: 'Повторить', onPressed: () => onRetry()),
        ]),
      );
}
