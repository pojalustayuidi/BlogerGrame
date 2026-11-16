import '../domain/economy_models.dart';

GameWallet walletFromJson(Map<String, dynamic> json) => GameWallet(
      coins: (json['coins'] as num).toInt(),
      lives: (json['lives'] as num).toInt(),
      hints: (json['hints'] as num).toInt(),
      maxLives: (json['maxLives'] as num).toInt(),
      maxHints: (json['maxHints'] as num).toInt(),
      lifeRegenMinutes: (json['lifeRegenMinutes'] as num).toInt(),
      nextLifeAt: json['nextLifeAt'] == null
          ? null
          : DateTime.parse(json['nextLifeAt'] as String),
    );

ShopOffer offerFromJson(Map<String, dynamic> json) => ShopOffer(
      sku: json['sku'] as String,
      kind: json['kind'] as String,
      quantity: (json['quantity'] as num).toInt(),
      costCoins: (json['costCoins'] as num).toInt(),
    );

PurchaseReceipt purchaseFromJson(Map<String, dynamic> json) => PurchaseReceipt(
      applied: json['applied'] == true,
      sku: json['sku'] as String,
      wallet: walletFromJson(Map<String, dynamic>.from(json['wallet'] as Map)),
    );
