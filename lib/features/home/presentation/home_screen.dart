import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prufani_theme.dart';
import '../../catalog/presentation/catalog_screens.dart';
import 'home_providers.dart';
import 'home_sheets.dart';
import 'home_widgets.dart';

/// Polish of the existing home feature, no legacy API and no duplicate menu.
class PrufaniHomeScreen extends ConsumerStatefulWidget {
  const PrufaniHomeScreen({super.key});

  @override
  ConsumerState<PrufaniHomeScreen> createState() => _PrufaniHomeScreenState();
}

class _PrufaniHomeScreenState extends ConsumerState<PrufaniHomeScreen> {
  Future<void> _refresh() async {
    ref.invalidate(homeOverviewProvider);
    try {
      await ref.read(homeOverviewProvider.future);
    } catch (_) {
      // AsyncValue renders the error; no guest data is cleared here.
    }
  }

  /// The home CTA is the only entry point into gameplay selection:
  /// Home -> packs -> levels -> server-confirmed attempt.
  /// Even "Продолжить" opens packs first, so the player can choose a pack.
  Future<void> _openPacks() async {
    await openPrufaniCategoriesPage(context);
    if (!mounted) return;
    ref.invalidate(homeOverviewProvider);
  }

  Future<void> _openTab(HomeTab tab) async {
    switch (tab) {
      case HomeTab.home:
        await _refresh();
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
  Widget build(BuildContext context) {
    final asyncOverview = ref.watch(homeOverviewProvider);
    final overview = asyncOverview.asData?.value;
    final padding = clampHomePadding(MediaQuery.sizeOf(context).width);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: PrufaniColors.cream,
        // Scaffold reserves vertical space for the navigation. It is never
        // overlaid on scrollable cards, including on shorter Android screens.
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 3),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: PrufaniBottomNavigation(
                onSelect: _openTab,
              ),
            ),
          ),
        ),
        body: Stack(children: [
          Positioned.fill(
            child: Image.asset(PrufaniAssets.background, fit: BoxFit.cover),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: PrufaniColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(padding, 2, padding, 24),
                    children: [
                      HomeBrandHeader(
                        onSettings: () => showPrufaniSettings(context),
                      ),
                      const SizedBox(height: 8),
                      if (overview != null)
                        ResourceStrip(
                          wallet: overview.wallet,
                          onCoins: () => showPrufaniShop(context, ref),
                          onLives: () =>
                              showPrufaniLives(context, overview.wallet),
                          onHints: () => showPrufaniShop(context, ref),
                          onRegenDue: () => _refresh(),
                        )
                      else
                        const _ResourcePlaceholder(),
                      const SizedBox(height: 16),
                      if (overview != null)
                        PrufaniProgressCard(
                          overview: overview,
                          onPrimaryAction: _openPacks,
                        )
                      else if (asyncOverview.hasError)
                        HomeErrorPanel(onRetry: _refresh)
                      else
                        const HomeLoadingPanel(),
                      const SizedBox(height: 16),
                      const HomeFeatureCards(),
                      const SizedBox(height: 12),
                      HomeRewardBanner(
                        onTap: () => showPrufaniRewards(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ResourcePlaceholder extends StatelessWidget {
  const _ResourcePlaceholder();

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
              child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6FF),
              borderRadius: BorderRadius.circular(19),
            ),
          )),
        ],
      ]);
}
