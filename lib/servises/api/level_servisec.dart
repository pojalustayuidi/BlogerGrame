import 'package:dio/dio.dart';
import '../models/level.dart';

class LevelService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://cryptogame-backend-production.up.railway.app';

  static Future<List<Level>> fetchLevels() async {
    try {
      final response = await _dio.get('$baseUrl/levels');

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((json) => Level.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при запросе: $e');
    }
  }
}
