import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com/player';

  static Future<String?> registerPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final saveId = prefs.getString('playerId');
    if (saveId != null) {
      return saveId;
    }

    try {
      final response = await _dio.post('$baseUrl/register');
      if (response.statusCode == 201) {
        final playerId = response.data['playerId'];
        await prefs.setString('playerId', playerId);
        return playerId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<int?> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      return null;
    }

    try {
      final response = await _dio.get('$baseUrl/$playerId/progress');
      if (response.statusCode == 200) {
        return response.data['currentLevel'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, int>?> getPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return null;

    try {
      final response = await _dio.get('$baseUrl/$playerId');
      if (response.statusCode == 200) {
        List<dynamic> progressList = response.data['progress'] ?? [];
        int completedLevels = progressList.length;
        int totalLevels = 8; // Можно сделать динамическим

        return {
          'completedLevels': completedLevels,
          'totalLevels': totalLevels,
          'coins': response.data['coins'] ?? 0,
          'hints': response.data['hints'] ?? 0,
          'lives': response.data['lives'] ?? 0,
        };
      }
    } catch (e) {
      print('Ошибка при получении статистики: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProgress(int levelId, int reward) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playerId = prefs.getString('playerId');
      if (playerId == null) return null;

      final response = await _dio.post(
        '$baseUrl/$playerId/update-progress',
        data: {'levelId': levelId, 'reward': reward},
      );

      return {
        'success': response.statusCode == 200,
        'coinsAdded': response.data['coinsAdded'] ?? reward,
        'newCoins': response.data['newCoins'] ?? 0,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> useHint({
    required int levelId,
    required int letterIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return null;

    try {
      final response = await _dio.post(
        '$baseUrl/$playerId/use-hint',
        data: {
          'levelId': levelId,
          'letterIndex': letterIndex,
        },
      );

      if (response.statusCode == 200) {
        return {
          'hints': response.data['hints'],
          'revealedIndices': List<int>.from(response.data['revealedIndices'] ?? []),
        };
      } else {
        return null;
      }
    } catch (e) {
      print('Ошибка использования подсказки: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      return null;
    }

    try {
      final response = await _dio.get('$baseUrl/$playerId/status');
      if (response.statusCode == 200) {
        return {
          'coins': response.data['coins'] ?? 0,
          'lives': response.data['lives'] ?? 0,
          'last_life_update': response.data['last_life_update'] ?? '',
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateStatus({int? coins, int? lives, String? lastLifeUpdate}) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      return false;
    }

    final Map<String, dynamic> data = {};
    if (coins != null) data['coins'] = coins;
    if (lives != null) data['lives'] = lives;
    if (lastLifeUpdate != null) data['last_life_update'] = lastLifeUpdate;

    if (data.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.post('$baseUrl/$playerId/update', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> refreshLives(String playerId) async {
    try {
      final response = await _dio.post('$baseUrl/$playerId/refresh-lives');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> decrementLives() async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      return false;
    }

    try {
      final response = await _dio.post('$baseUrl/$playerId/decrement-lives');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restoreHints(int amount, int cost) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return false;

    try {
      final response = await _dio.post(
        '$baseUrl/$playerId/restore-hints',
        data: {'amount': amount, 'cost': cost},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка восстановления подсказок: $e');
      return false;
    }
  }

  static Future<void> clearPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('playerId');
  }

  static Future<String> getCurrentPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playerId') ?? '';
  }
}