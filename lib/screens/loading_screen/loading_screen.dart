import 'package:flutter/material.dart';
import '../../servises/models/level.dart';
import '../../servises/player_sevice.dart';
import '../menu_screen/menu_screen.dart';
import 'package:dio/dio.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late Dio dio;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    initializeGame();
  }

  Future<void> initializeGame() async {
    // 1. Регистрация игрока
    final playerId = await PlayerService.registerPlayer();

    if (playerId == null) {
      showError('Не удалось зарегистрировать игрока');
      return;
    }

    // 2. Получение прогресса
    final currentLevelIndex = await PlayerService.getCurrentLevel();

    // 3. Загрузка всех уровней
    try {
      final response = await dio.get('https://blogergramegame-backend.onrender.com/levels');
      final List data = response.data;
      final levels = data.map((json) => Level.fromJson(json)).toList();

      if (levels.isEmpty) {
        showError('Нет доступных уровней');
        return;
      }

      // 4. Переход на MenuScreen
      final levelIndex = currentLevelIndex ?? 0;
      final startingLevel = levels[levelIndex.clamp(0, levels.length - 1)];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuScreen(levels: levels, currentLevel: startingLevel,),
        ),
      );
    } catch (e) {
      showError('Ошибка при загрузке уровней: $e');
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
