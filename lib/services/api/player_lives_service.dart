import 'package:dio/dio.dart';

class PlayerLivesService {
  final Dio dio;
  final String playerId;

  PlayerLivesService({required this.dio, required this.playerId});

  Future<int> getLives() async {
    final response = await dio.get('/player/$playerId/status');
    return response.data['lives'] ?? 0;
  }


  Future<void> decrementLives() async {
    final currentLives = await getLives();
    if (currentLives > 0) {
      await dio.post('/player/$playerId/update', data: {'lives': currentLives - 1});
    }
  }

  Future<void> refreshLives() async {
    await dio.post('/player/$playerId/refresh-lives');
  }
}
