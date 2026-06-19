import 'package:flutter/material.dart';
import '../../../services/models/shop_item.dart';

class ShopItemCard extends StatelessWidget {
  final ShopItem item;
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

  @override
  Widget build(BuildContext context) {
    final canBuy = playerPoints >= item.cost;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;

        final padding = compact ? 12.0 : 14.0;
        final iconBoxHeight = compact ? 82.0 : 92.0;
        final iconSize = compact ? 34.0 : 40.0;
        final titleSize = compact ? 13.5 : 15.0;
        final priceSize = compact ? 13.0 : 14.0;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: canBuy ? onBuy : onInsufficientFunds,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: canBuy
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: canBuy
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: iconBoxHeight,
                    decoration: BoxDecoration(
                      color: canBuy
                          ? const Color(0xFFEEF4FF)
                          : const Color(0xFFECEFF3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: _buildItemIcon(item, iconSize, canBuy),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: canBuy
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: canBuy
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/coins.png',
                          width: compact ? 17 : 19,
                          height: compact ? 17 : 19,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.monetization_on_rounded,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.cost}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: priceSize,
                              fontWeight: FontWeight.w800,
                              color: canBuy
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          canBuy
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.lock_outline_rounded,
                          size: 14,
                          color: canBuy
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemIcon(ShopItem item, double size, bool canBuy) {
    if (item.type == 'life') {
      return Icon(
        Icons.favorite_rounded,
        color: canBuy ? Colors.redAccent : const Color(0xFF9CA3AF),
        size: size,
      );
    }

    if (item.type == 'hint') {
      return Icon(
        Icons.lightbulb_rounded,
        color: canBuy ? const Color(0xFF5B8DEF) : const Color(0xFF9CA3AF),
        size: size,
      );
    }

    return Icon(
      Icons.card_giftcard_rounded,
      color: canBuy ? const Color(0xFF5B8DEF) : const Color(0xFF9CA3AF),
      size: size,
    );
  }
}