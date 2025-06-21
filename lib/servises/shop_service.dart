import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com/shop';

  static Future<List<Map<String, dynamic>>> fetchShopItems() async {
    try {
      final response = await _dio.get('$baseUrl/items');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке магазина: $e');
      rethrow;
    }
  }

  static Future<bool> buyItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return false;

    try {
      final response = await _dio.post(
        '$baseUrl/buy',
        data: {
          'playerId': playerId,
          'itemId': itemId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при покупке: $e');
      return false;
    }
  }
}
