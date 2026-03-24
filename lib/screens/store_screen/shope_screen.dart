import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/models/shop_item.dart';
import '../../services/api/shop_service.dart';
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
      _showDialog('Недостаточно монет');
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

        _showMessage('Покупка успешна!');
      } else {
        _showMessage('Ошибка при покупке');
      }
    } catch (e) {
      _showMessage('Ошибка: $e');
    } finally {
      setState(() => _isBuying = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: text.contains('успешна') ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Упс!'),
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

  @override
  Widget build(BuildContext context) {
    // Слушаем провайдеры
    final playerAsync = ref.watch(playerProvider);
    final shopItemsAsync = ref.watch(shopItemsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Фон
          Positioned.fill(
            child: Image.asset(
              'assets/backgoround_shop.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF4A6FA5),
              ),
            ),
          ),

          // Контент
          Column(
            children: [
              // AppBar с кнопкой назад
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFDF0DC)),
                  onPressed: () => Navigator.pop(context),
                ),
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final fontSize = screenWidth * 0.06;
                    const maxFontSize = 26.0;
                    const minFontSize = 16.0;

                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'НАЗАД В ГЛАВНОЕ МЕНЮ',
                        style: TextStyle(
                          fontFamily: 'Franklin',
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFDF0DC),
                          fontSize: fontSize.clamp(minFontSize, maxFontSize),
                        ),
                      ),
                    );
                  },
                ),
                centerTitle: true,
                toolbarHeight: kToolbarHeight * 1.2,
              ),

              // Информация о ресурсах игрока
              playerAsync.when(
                data: (player) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 42),
                      const SizedBox(width: 6),
                      Text(
                        '${player.lives}/5',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'baloo',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 100),
                      Image.asset(
                        'assets/coins.png',
                        width: 42,
                        height: 42,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 42),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${player.coins}',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'baloo',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 25),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ошибка загрузки данных'),
                ),
              ),

              // Заголовок МАГАЗИН
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'МАГАЗИН',
                  style: TextStyle(
                    fontFamily: 'Franklin',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDF0DC),
                    fontSize: 32,
                  ),
                ),
              ),

              // Сетка товаров
              Expanded(
                child: shopItemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'Товары временно отсутствуют',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final player = playerAsync.valueOrNull;

                        return ShopItemCard(
                          item: item,  // Передаем объект ShopItem, а не Map
                          playerPoints: player?.coins ?? 0,
                          onBuy: () => _buyItem(item),
                          onInsufficientFunds: () => _showDialog('Недостаточно монет'),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки: $error',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(shopItemsProvider),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_isBuying)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}