import 'package:blogergrame/screens/store_screen/shop_widgets/shop_item_card.dart';
import 'package:flutter/material.dart';
import '../../servises/player_sevice.dart';
import '../../servises/shop_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Map<String, dynamic>> _items = [];
  int _playerPoints = 0;
  int _playerLives = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() => _loading = true);
    final items = await ShopService.fetchShopItems();
    final status = await PlayerService.getStatus();
    setState(() {
      _items = items;
      _playerPoints = status?['coins'] ?? 0;
      _playerLives = status?['lives'] ?? 0;
      _loading = false;
    });
  }

  Future<void> _buyItem(String itemId, int cost) async {
    if (_playerPoints < cost) {
      _showMessage('Недостаточно монет');
      return;
    }

    final success = await ShopService.buyItem(itemId);
    if (success) {
      _showMessage('Покупка успешна!');
      await _loadShopData();
    } else {
      _showMessage('Ошибка при покупке');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgoround_shop.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'НАЗАД В ГЛАВНОЕ МЕНЮ',
                  style: TextStyle(
                    fontFamily: 'Franklin',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDF0DC),
                    fontSize: 26,
                  ),
                ),
                centerTitle: true,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 42),
                    const SizedBox(width: 6),
                    Text('$_playerLives' '/5',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'baloo')),
                    const SizedBox(
                      width: 100,
                    ),
                    Image.asset('assets/coins.png', ),
                    const SizedBox(width: 6),
                    Text('$_playerPoints',
                        style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'baloo')),
                    const SizedBox(width: 25),
                  ],
                ),
              ),
              const Column(
                children: [
                  Text(
                    'МАГАЗИН',
                    style: TextStyle(
                      fontFamily: 'Franklin',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDF0DC),
                      fontSize: 32,
                    ),
                  )
                ],
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  childAspectRatio: 0.9,
                  children: _items.map((item) {
                    return ShopItemCard(
                      item: item,
                      playerPoints: _playerPoints,
                      onBuy: () => _buyItem(item['id'], item['cost']),
                      onInsufficientFunds: () =>
                          _showDialog('Недостаточно монет'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
