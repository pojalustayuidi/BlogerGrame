import 'package:flutter/material.dart';

class ShopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int playerPoints;
  final VoidCallback onBuy;
  final VoidCallback onInsufficientFunds; // новый коллбэк

  const ShopItemCard({
    super.key,
    required this.item,
    required this.playerPoints,
    required this.onBuy,
    required this.onInsufficientFunds,
  });

  Widget _buildItemIcon(String type) {
    if (type == 'hint') {
      return const Icon(Icons.lightbulb, color: Colors.orange, size: 48);
    } else if (type == 'life') {
      return const Icon(Icons.favorite, color: Colors.red, size: 48);
    }
    return const Icon(Icons.extension, size: 48);
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = playerPoints >= item['cost'];

    return GestureDetector(
      onTap: () {
        if (canAfford) {
          onBuy();
        } else {
          onInsufficientFunds();
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildItemIcon(item['type']),
            const SizedBox(height: 12),
            Text(
              item['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/coins.png', ),
                const SizedBox(width: 4),
                Text(
                  '${item['cost']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: canAfford ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

