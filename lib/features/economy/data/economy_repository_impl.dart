import '../../../core/network/authenticated_api_client.dart';
import '../domain/economy_models.dart';
import '../domain/economy_repository.dart';
import 'economy_mapper.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  final AuthenticatedApiClient _client;

  const EconomyRepositoryImpl(this._client);

  @override
  Future<GameWallet> wallet() async {
    final json = await _client.request('GET', '/api/v1/game/wallet');
    return walletFromJson(Map<String, dynamic>.from(json['wallet'] as Map));
  }

  @override
  Future<List<ShopOffer>> shopOffers() async {
    final json = await _client.request('GET', '/api/v1/game/shop');
    return (json['offers'] as List<dynamic>)
        .map((item) => offerFromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  @override
  Future<PurchaseReceipt> buyShopItem({
    required String sku,
    required String requestId,
  }) async {
    final json = await _client.request('POST', '/api/v1/game/shop/purchases',
        data: {'sku': sku, 'requestId': requestId});
    return purchaseFromJson(json);
  }
}
