import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com/player';

  static Future<String?> registerPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final saveId = prefs.getString('playerId');
    if (saveId != null) {
      print('Используется существующий playerId: $saveId');
      return saveId;
    }

    try {
      final response = await _dio.post('$baseUrl/register');
      if (response.statusCode == 201) {
        final playerId = response.data['playerId'];
        await prefs.setString('playerId', playerId);
        print('Зарегистрирован новый playerId: $playerId');
        return playerId;
      } else {
        print('Ошибка регистрации: статус ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при регистрации: $e');
      return null;
    }
  }

  static Future<int?> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для получения прогресса');
      return null;
    }

    try {
      final response = await _dio.get('$baseUrl/$playerId/progress');
      if (response.statusCode == 200) {
        print('Прогресс получен: ${response.data}');
        return response.data['currentLevel'];
      } else {
        print('Ошибка получения прогресса: статус ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при получении прогресса: $e');
      return null;
    }
  }

  static Future<bool> updateProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для обновления прогресса');
      return false;
    }
    try {
      final response = await _dio.post('$baseUrl/progress', data: {'playerId': playerId, 'levelId': levelId});
      print('Прогресс обновлён: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при обновлении прогресса: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для получения статуса');
      return null;
    }

    try {
      final response = await _dio.get('$baseUrl/$playerId/status');
      if (response.statusCode == 200) {
        print('Ответ /status: ${response.data}');
        return {
          'coins': response.data['coins'] ?? 0,
          'lives': response.data['lives'] ?? 0,
          'last_life_update': response.data['last_life_update'] ?? '',
        };
      } else {
        print('Ошибка получения статуса: статус ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при получении статуса: $e');
      return null;
    }
  }

  static Future<bool> updateStatus({int? coins, int? lives, String? lastLifeUpdate}) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для обновления статуса');
      return false;
    }

    final Map<String, dynamic> data = {};
    if (coins != null) data['coins'] = coins;
    if (lives != null) data['lives'] = lives;
    if (lastLifeUpdate != null) data['last_life_update'] = lastLifeUpdate;

    if (data.isEmpty) {
      print('Нет данных для обновления статуса');
      return false;
    }

    try {
      final response = await _dio.post('$baseUrl/$playerId/update', data: data);
      print('Обновление статуса: $data, результат: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при обновлении статуса: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> refreshLives(String playerId) async {
    try {
      final response = await _dio.post('$baseUrl/$playerId/refresh-lives');
      if (response.statusCode == 200) {
        print('Ответ /refresh-lives: ${response.data}');
        return response.data;
      } else {
        print('Ошибка восстановления жизней: статус ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при восстановлении жизней: $e');
      return null;
    }
  }

  static Future<bool> decrementLives() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для уменьшения жизней');
      return false;
    }

    try {
      final response = await _dio.post('$baseUrl/$playerId/decrement-lives');
      print('Уменьшение жизней: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при уменьшении жизней: $e');
      return false;
    }
  }

  static Future<void> clearPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('playerId');
    print('playerId очищен');
  }
}