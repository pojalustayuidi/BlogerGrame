import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://blogergramegame-backend.onrender.com/player';

  static Future<String?> registerPlayer() async{
    final prefs = await SharedPreferences.getInstance();
    final saveId = prefs.getString('playerId');
    if (saveId  != null) return saveId;


    try {
      final response = await _dio.post('$baseUrl/register');
      if (response.statusCode == 201){
        final playerId = response.data['playerId'];
        await prefs.setString('playerId', playerId);
        return playerId;
      }
    } catch (e){
      print("Ошибка при регистрации $e");
    }
    return null;
  }

  static Future<int?> getCurrentLevel() async{
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return null;

    try {
      final response = await _dio.get('$baseUrl/$playerId/progress');
      if (response.statusCode == 200){
        return response.data['currentLevel'];
      }
    } catch (e){
      print('Ошибка при получение прогресса $e ');
    }
return null;
  }

  static Future<bool> updateProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) return false;
    try {
      final response = await _dio.post('$baseUrl/progress', data: {'playerId': playerId, 'levelId': levelId });
    return response.statusCode == 200;
    } catch (e){
      print('Ошибка при обновление прогресса: $e');
      return false;
    }
  }
}