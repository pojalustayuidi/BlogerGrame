import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/api/shop_service.dart';
import '../../services/models/shop_item.dart';
import 'shop_widgets/shop_item_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isBuying = false;

  Future<void> _buyItem(ShopItem item) async {
    if (_isBuying) return;

    final player = ref.read(playerProvider).valueOrNull;
    if (player == null) return;

    if (player.coins < item.cost) {
      _showInfoDialog('Недостаточно монет');
      return;
    }

    setState(() => _isBuying = true);

    try {
      final success = await ShopService.buyItem(item.id);

      if (success) {
        if (item.type == 'hint') {
          ref.read(playerProvider.notifier).updateHints(player.hints + 1);
        } else if (item.type == 'life') {
          final newLives = (player.lives + 1).clamp(0, 5);
          ref.read(playerProvider.notifier).updateLives(newLives);
        }

        ref.read(playerProvider.notifier).updateCoins(player.coins - item.cost);

        _showSnackBar('Покупка успешна', isSuccess: true);
      } else {
        _showSnackBar('Ошибка при покупке');
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      if (mounted) {
        setState(() => _isBuying = false);
      }
    }
  }

  void _showSnackBar(String text, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isSuccess
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Упс!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(playerProvider);
    ref.invalidate(shopItemsProvider);

    await Future.wait([
      ref.read(playerProvider.future),
      ref.read(shopItemsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);
    final shopItemsAsync = ref.watch(shopItemsProvider);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -30,
            right: -30,
            child: Container(
              height: 250,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(44),
                  bottomRight: Radius.circular(44),
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _ShopTopBar(
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 18),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ShopTitleBlock(),
                            const SizedBox(height: 14),
                            playerAsync.when(
                              data: (player) => _AdaptiveResourcesRow(
                                lives: player.lives,
                                maxLives: 5,
                                coins: player.coins,
                                hints: player.hints,
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (_, __) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'Не удалось загрузить ресурсы',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Доступные товары',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 12),
                            shopItemsAsync.when(
                              data: (items) {
                                if (items.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: const Text(
                                      'Товары временно отсутствуют',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  );
                                }

                                final player = playerAsync.valueOrNull;

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final gridWidth = constraints.maxWidth;

                                    int crossAxisCount;
                                    if (gridWidth >= 900) {
                                      crossAxisCount = 4;
                                    } else if (gridWidth >= 680) {
                                      crossAxisCount = 3;
                                    } else {
                                      crossAxisCount = 2;
                                    }

                                    final spacing = gridWidth < 380 ? 10.0 : 12.0;
                                    final itemWidth = (gridWidth -
                                        (crossAxisCount - 1) * spacing) /
                                        crossAxisCount;
                                    final itemHeight = itemWidth * 1.28;

                                    return GridView.builder(
                                      itemCount: items.length,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                        mainAxisExtent: itemHeight,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = items[index];

                                        return ShopItemCard(
                                          item: item,
                                          playerPoints: player?.coins ?? 0,
                                          onBuy: () => _buyItem(item),
                                          onInsufficientFunds: () =>
                                              _showInfoDialog('Недостаточно монет'),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 36),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (error, _) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 44,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Ошибка загрузки: $error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ElevatedButton(
                                      onPressed: () => ref.invalidate(shopItemsProvider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5B8DEF),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Text('Повторить'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: width < 380 ? 18 : 24),
                  ),
                ],
              ),
            ),
          ),
          if (_isBuying)
            Container(
              color: Colors.black.withOpacity(0.16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _ShopTopBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: const Text(
              'Магазин',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopTitleBlock extends StatelessWidget {
  const _ShopTitleBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Color(0xFF5B8DEF),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Магазин бонусов',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Покупай жизни, подсказки и полезные бонусы',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdaptiveResourcesRow extends StatelessWidget {
  final int lives;
  final int maxLives;
  final int coins;
  final int hints;

  const _AdaptiveResourcesRow({
    required this.lives,
    required this.maxLives,
    required this.coins,
    required this.hints,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        final items = [
          _ResourceMiniCard(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
            value: '$lives/$maxLives',
            label: 'Жизни',
          ),
          _ResourceMiniCard(
            icon: Image.asset(
              'assets/coins.png',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 24),
            ),
            value: '$coins',
            label: 'Монеты',
          ),
          _ResourceMiniCard(
            icon: Image.asset(
              'assets/icon_hint.png',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 24),
            ),
            value: '$hints',
            label: 'Подсказки',
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 10),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: items[2]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 10),
            Expanded(child: items[1]),
            const SizedBox(width: 10),
            Expanded(child: items[2]),
          ],
        );
      },
    );
  }
}

class _ResourceMiniCard extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _ResourceMiniCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}