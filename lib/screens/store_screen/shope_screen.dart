import 'package:flutter/material.dart';
import '../../servises/player_sevice.dart';
import '../../servises/shop_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

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

  Widget _buildItemIcon(String type) {
    if (type == 'hint') {
      return Icon(Icons.lightbulb_outline, color: Colors.orange);
    } else if (type == 'life') {
      return Icon(Icons.favorite, color: Colors.red);
    }
    return Icon(Icons.extension);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Магазин')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                const SizedBox(width: 6),
                Text('$_playerPoints', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 24),
                Icon(Icons.favorite, color: Colors.red, size: 28),
                const SizedBox(width: 6),
                Text('$_playerLives', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final item = _items[index];
                final canAfford = _playerPoints >= item['cost'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _buildItemIcon(item['type']),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['description']),
                    trailing: ElevatedButton(
                      onPressed: canAfford ? () => _buyItem(item['id'], item['cost']) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? null : Colors.grey,
                      ),
                      child: Text('Купить (${item['cost']})'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
