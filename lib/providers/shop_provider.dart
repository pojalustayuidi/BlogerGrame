import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api/shop_service.dart';
import '../services/models/shop_item.dart';

part 'shop_provider.g.dart';

@riverpod
class ShopItems extends _$ShopItems {
  @override
  Future<List<ShopItem>> build() async {
    print('Загружаем товары магазина...');

    try {
      final itemsJson = await ShopService.fetchShopItems();
      final items = itemsJson.map((json) => ShopItem.fromJson(json)).toList();
      print('Загружено ${items.length} товаров');
      return items;
    } catch (e) {
      print('Ошибка загрузки товаров: $e');
      throw Exception('Ошибка загрузки магазина: $e');
    }
  }
}

final purchaseProvider = StateProvider<bool>((ref) => false);