class GameWallet {
  final int coins;
  final int lives;
  final int hints;
  final int maxLives;
  final int maxHints;
  final int lifeRegenMinutes;
  final DateTime? nextLifeAt;

  const GameWallet({
    required this.coins,
    required this.lives,
    required this.hints,
    required this.maxLives,
    required this.maxHints,
    required this.lifeRegenMinutes,
    required this.nextLifeAt,
  });
}

class ShopOffer {
  final String sku;
  final String kind;
  final int quantity;
  final int costCoins;

  const ShopOffer({
    required this.sku,
    required this.kind,
    required this.quantity,
    required this.costCoins,
  });
}

class PurchaseReceipt {
  final bool applied;
  final String sku;
  final GameWallet wallet;

  const PurchaseReceipt({
    required this.applied,
    required this.sku,
    required this.wallet,
  });
}
