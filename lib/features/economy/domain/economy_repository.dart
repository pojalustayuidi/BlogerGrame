import 'economy_models.dart';

abstract class EconomyRepository {
  Future<GameWallet> wallet();
  Future<List<ShopOffer>> shopOffers();

  /// Never send client-calculated costs or resource deltas.
  Future<PurchaseReceipt> buyShopItem({
    required String sku,
    required String requestId,
  });
}
