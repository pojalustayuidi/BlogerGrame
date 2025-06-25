import 'package:flutter/material.dart';

class ShopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int playerPoints;
  final VoidCallback onBuy;
  final VoidCallback onInsufficientFunds;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.playerPoints,
    required this.onBuy,
    required this.onInsufficientFunds,
  });

  Widget _buildItemIcon(String type, double size) {
    if (type == 'hint') {
      return Icon(Icons.lightbulb, color: Colors.orange, size: size);
    } else if (type == 'life') {
      return Icon(Icons.favorite, color: Colors.red, size: size);
    }
    return Icon(Icons.extension, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = playerPoints >= item['cost'];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final cardWidth = screenWidth * 0.8;
    final iconSize = screenHeight * 0.08;
    final fontSize = screenWidth * 0.04;
    final coinSize = screenWidth * 0.06;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (canAfford) {
              onBuy();
            } else {
              onInsufficientFunds();
            }
          },
          child: Container(
            width: constraints.maxWidth > 600 ? 280 : cardWidth,
            constraints: const BoxConstraints(
              maxWidth: 400,
              minWidth: 150,
            ),
            padding: EdgeInsets.all(screenWidth * 0.03),
            margin: EdgeInsets.all(screenWidth * 0.02),
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
                _buildItemIcon(item['type'], iconSize),
                SizedBox(height: screenHeight * 0.015),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/coins.png',
                      width: coinSize,
                      height: coinSize,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      '${item['cost']}',
                      style: TextStyle(
                        fontSize: fontSize,
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
      },
    );
  }
}
