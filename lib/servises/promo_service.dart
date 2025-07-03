import 'package:dio/dio.dart';

class PromoService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com';

  static Future<Map<String, dynamic>?> redeemPromoCode({
    required String playerId,
    required String promoCode,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/redeem',
        data: {
          'playerId': playerId,
          'code': promoCode,
        },
      );

      return {
        'success': true,
        'message': response.data['message'],
        'reward_coins': response.data['reward_coins'] ?? 0,
        'reward_hints': response.data['reward_hints'] ?? 0,
        'reward_lives': response.data['reward_lives'] ?? 0,
      };
    } on DioException catch (e) {
      // Это ошибка от сервера с кодом 400/404 и т.д.
      if (e.response != null && e.response?.data != null) {
        return {
          'success': false,
          'error': e.response?.data['error'] ?? 'Неизвестная ошибка от сервера',
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка соединения с сервером',
        };
      }
    } catch (e) {
      print('Неизвестная ошибка: $e');
      return {
        'success': false,
        'error': 'Неизвестная ошибка',
      };
    }
  }

}