import 'package:dio/dio.dart';
import '../models/level.dart';

class LevelService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com';

  static Future<Level> fetchLevelById(int id) async {
    try {
      final response = await _dio.get('$baseUrl/levels/$id');

      if (response.statusCode == 200) {
        return Level.fromJson(response.data);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при запросе уровня: $e');
    }
  }

  }

