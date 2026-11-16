import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../../../core/theme/prufani_theme.dart';
import '../../economy/domain/economy_models.dart';
import '../../game/domain/game_models.dart';
import '../../home/presentation/home_providers.dart';
import '../../home/presentation/home_sheets.dart';
import '../../home/presentation/home_widgets.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';
import 'catalog_widgets.dart';

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
    final wallet = ref.watch(homeOverviewProvider).asData?.value.wallet;
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
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 26),
          children: [
            _CatalogTopBar(
              wallet: wallet,
              onBack: () => Navigator.of(context).pop(),
              onCoins: () => showPrufaniShop(context, ref),
              onLives: wallet == null
                  ? null
                  : () => showPrufaniLives(context, wallet),
            ),
            const SizedBox(height: 13),
            const _CategoriesHero(),
            const SizedBox(height: 15),
            packsAsync.when(
              loading: () => const _CatalogLoading(),
              error: (_, __) => _CatalogFailure(
                title: 'Не удалось загрузить паки',
                onRetry: () => _refresh(ref),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _CatalogEmpty('Пока нет доступных категорий.');
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 315;
                  return Column(children: [
                    for (var index = 0; index < items.length; index += 2) ...[
                      if (index + 1 < items.length && twoColumns)
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _packCard(context, ref, items[index])),
                              const SizedBox(width: 11),
                              Expanded(
                                  child: _packCard(
                                      context, ref, items[index + 1])),
                            ])
                      else
                        _packCard(context, ref, items[index], wide: twoColumns),
                      const SizedBox(height: 13),
                      if (!twoColumns && index + 1 < items.length) ...[
                        _packCard(context, ref, items[index + 1], wide: true),
                        const SizedBox(height: 13),
                      ],
                    ],
                    const Padding(
                      padding: EdgeInsets.fromLTRB(13, 4, 13, 0),
                      child: Text(
                        'Выбирай любимый пак, проходи уровни и открывай новые цитаты!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: PrufaniColors.muted,
                            height: 1.3,
                            fontSize: 12.5),
                      ),
                    ),
                  ]);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _packCard(
          BuildContext context, WidgetRef ref, PrufaniCategoryProgress progress,
          {bool wide = false}) =>
      PrufaniCategoryCard(
        progress: progress,
        wide: wide,
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
  int? _chosenPage;

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
    setState(() => _opening = true);
    try {
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
      await showPrufaniAttempt(context, attempt);
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

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(catalogLevelsProvider(widget.categorySlug));
    final wallet = ref.watch(homeOverviewProvider).asData?.value.wallet;
    final saved = ref.watch(homeOverviewProvider).asData?.value.activeAttempt;
    final matchingAttempt =
        saved?.category == widget.categorySlug && saved?.status == 'in_progress'
            ? saved
            : null;
    final ordered = levelsAsync.asData?.value.toList()
      ?..sort((a, b) => a.number.compareTo(b.number));
    final pending = ordered == null
        ? const <LevelSummary>[]
        : ordered.where((level) => !level.completed).toList();
    LevelSummary? selectedLevel;
    if (pending.isNotEmpty) {
      selectedLevel = pending.first;
      if (matchingAttempt != null) {
        for (final level in pending) {
          if (level.id == matchingAttempt.levelId) {
            selectedLevel = level;
            break;
          }
        }
      }
    }
    final selectedIndex = selectedLevel == null || ordered == null
        ? 0
        : ordered.indexWhere((level) => level.id == selectedLevel!.id);
    final pageCount = levelPageCount(ordered?.length ?? 0);
    final page = (_chosenPage ??
            (selectedIndex < 0 ? 0 : selectedIndex ~/ prufaniLevelsPerPage))
        .clamp(0, pageCount - 1)
        .toInt();
    final visible =
        ordered == null ? <LevelSummary>[] : levelsForPage(ordered, page);

    return _CatalogScaffold(
      bottomAction: _LevelBottomAction(
        active: matchingAttempt != null &&
            selectedLevel?.id == matchingAttempt.levelId,
        enabled: !_opening && selectedLevel != null,
        onTap: selectedLevel == null
            ? null
            : () => _openLevel(
                  selectedLevel!,
                  matchingAttempt?.levelId == selectedLevel!.id
                      ? matchingAttempt
                      : null,
                ),
      ),
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: PrufaniColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 15),
          children: [
            _CatalogTopBar(
              wallet: wallet,
              onBack: () => Navigator.of(context).pop(),
              onCoins: () => showPrufaniShop(context, ref),
              onLives: wallet == null
                  ? null
                  : () => showPrufaniLives(context, wallet),
            ),
            const SizedBox(height: 11),
            _LevelHero(
              slug: widget.categorySlug,
              title:
                  widget.categoryTitle ?? _categoryTitle(widget.categorySlug),
              completed: ordered?.where((level) => level.completed).length ?? 0,
              total: ordered?.length ?? 0,
            ),
            const SizedBox(height: 12),
            if (_opening) ...[
              const LinearProgressIndicator(
                  color: PrufaniColors.primary, minHeight: 3),
              const SizedBox(height: 7),
            ],
            levelsAsync.when(
              loading: () => const _CatalogLoading(),
              error: (_, __) => _CatalogFailure(
                  title: 'Не удалось загрузить уровни', onRetry: _refresh),
              data: (data) => data.isEmpty
                  ? const _CatalogEmpty('В этом паке пока нет уровней.')
                  : _LevelBoard(
                      levels: visible,
                      page: page,
                      pageCount: pageCount,
                      recommendedId: selectedLevel?.id,
                      activeAttempt: matchingAttempt,
                      opening: _opening,
                      onPage: (next) => setState(() => _chosenPage = next),
                      onLevel: (level) => _openLevel(
                        level,
                        matchingAttempt?.levelId == level.id
                            ? matchingAttempt
                            : null,
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

class _CategoriesHero extends StatelessWidget {
  const _CategoriesHero();

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          height: 107,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF9F58ED), Color(0xFF6930C5)]),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: const Color(0xC9FFFFFF), width: 1.5),
            boxShadow: catalogCardShadow,
          ),
          child: Stack(children: [
            Positioned(
                top: -12,
                right: 15,
                child: Opacity(
                    opacity: .75,
                    child: Image.asset(PrufaniAssets.crown,
                        width: 67, height: 64))),
            Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                    TextSpan(children: const [
                      TextSpan(
                          text: 'Выбери ',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: 'категорию',
                          style: TextStyle(color: Color(0xFFFFE066))),
                    ]),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                            color: Color(0x5D34187B),
                            blurRadius: 4,
                            offset: Offset(0, 3))
                      ],
                    )),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 9),
        const Text('Угадывай цитаты любимых авторов и получай награды!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: PrufaniColors.primaryDark,
                fontWeight: FontWeight.w700)),
      ]);
}

class _LevelHero extends StatelessWidget {
  const _LevelHero(
      {required this.slug,
      required this.title,
      required this.completed,
      required this.total});
  final String slug;
  final String title;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : completed / total;
    return Container(
      height: 162,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slug == 'streamers'
              ? const [Color(0xFF9C50EC), Color(0xFF6527CC)]
              : categoryGradient(slug),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xD1FFFFFF)),
        boxShadow: catalogCardShadow,
      ),
      child: Column(children: [
        Expanded(
            child: Row(children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: slug == 'streamers'
                              ? Colors.white
                              : PrufaniColors.ink))),
              const SizedBox(height: 5),
              Text(categoryCaption(slug),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: slug == 'streamers'
                          ? const Color(0xFFF1E1FF)
                          : PrufaniColors.primaryDark,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600)),
            ],
          )),
          Image.asset(categoryIllustration(slug),
              width: 100, height: 93, fit: BoxFit.contain),
        ])),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
                color: const Color(0xFFFDF4FF),
                borderRadius: BorderRadius.circular(17)),
            child: Row(children: [
              Image.asset('assets/prufani/icons/resources/star.png',
                  width: 20, height: 20),
              const SizedBox(width: 4),
              Text('$completed/$total',
                  style: const TextStyle(
                      color: PrufaniColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 9),
          Expanded(
              child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0).toDouble(),
                minHeight: 12,
                backgroundColor: const Color(0x663E1365),
                color: const Color(0xFFFFD52D),
              ),
            ),
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xE9FAE8FF),
                borderRadius: BorderRadius.circular(13)),
            child: Text('${(fraction * 100).round()}%',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: PrufaniColors.primaryDark)),
          ),
        ]),
      ]),
    );
  }
}

class _LevelBoard extends StatelessWidget {
  const _LevelBoard(
      {required this.levels,
      required this.page,
      required this.pageCount,
      required this.recommendedId,
      required this.activeAttempt,
      required this.opening,
      required this.onPage,
      required this.onLevel});
  final List<LevelSummary> levels;
  final int page;
  final int pageCount;
  final String? recommendedId;
  final PuzzleAttempt? activeAttempt;
  final bool opening;
  final ValueChanged<int> onPage;
  final ValueChanged<LevelSummary> onLevel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 15, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8EFFF),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: catalogCardShadow,
        ),
        child: Column(children: [
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth < 290 ? 4 : 5;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: levels.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: columns == 5 ? 91 : 94,
                mainAxisSpacing: 9,
                crossAxisSpacing: 7,
              ),
              itemBuilder: (context, index) {
                final level = levels[index];
                final isActive = activeAttempt?.levelId == level.id;
                return PrufaniLevelTile(
                  key: ValueKey(level.id),
                  level: level,
                  isActive: isActive,
                  isRecommended: level.id == recommendedId,
                  onTap:
                      opening || level.completed ? null : () => onLevel(level),
                );
              },
            );
          }),
          const SizedBox(height: 13),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _CircleArrow(
              icon: Icons.chevron_left_rounded,
              enabled: page > 0,
              onTap: () => onPage(page - 1),
            ),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < pageCount; index++)
                  if (pageCount <= 7 ||
                      index == page ||
                      (index - page).abs() <= 1) ...[
                    GestureDetector(
                      onTap: () => onPage(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == page ? 13 : 9,
                        height: index == page ? 13 : 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == page
                              ? const Color(0xFFFFCC28)
                              : const Color(0xFFC9A3F5),
                        ),
                      ),
                    ),
                  ],
                if (pageCount > 7)
                  Text(' ${page + 1}/$pageCount',
                      style: const TextStyle(
                          fontSize: 11, color: PrufaniColors.primaryDark)),
              ],
            )),
            _CircleArrow(
              icon: Icons.chevron_right_rounded,
              enabled: page < pageCount - 1,
              onTap: () => onPage(page + 1),
            ),
          ]),
        ]),
      );
}

class _CircleArrow extends StatelessWidget {
  const _CircleArrow(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFFFFFFF),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          color: PrufaniColors.primaryDark,
          disabledColor: const Color(0xFFCCBBDC),
          iconSize: 25,
          tooltip: enabled ? 'Другая страница уровней' : 'Нет страниц',
        ),
      );
}

class _LevelBottomAction extends StatelessWidget {
  const _LevelBottomAction(
      {required this.enabled, required this.active, required this.onTap});
  final bool enabled;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 7),
        child: SizedBox(
          height: 59,
          child: Material(
            borderRadius: BorderRadius.circular(28),
            color: enabled ? const Color(0xFFFFD62D) : const Color(0xFFE3D8E5),
            elevation: enabled ? 3 : 0,
            shadowColor: const Color(0x88683AC4),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(28),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.play_arrow_rounded,
                    size: 27,
                    color: enabled
                        ? PrufaniColors.primaryDark
                        : PrufaniColors.muted),
                const SizedBox(width: 9),
                Text(
                    enabled
                        ? (active ? 'Продолжить' : 'Играть')
                        : 'Всё пройдено',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: PrufaniColors.ink)),
              ]),
            ),
          ),
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
