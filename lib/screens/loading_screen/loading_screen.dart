import 'package:flutter/material.dart';
import '../../servises/api/level_servisec.dart';
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
  String? playerId;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    initializeGame();
  }

  Future<void> initializeGame() async {

    final id = await PlayerService.registerPlayer();

    if (id == null) {
      showError('Не удалось зарегистрировать игрока');
      return;
    }

    setState(() {
      playerId = id;
    });
    await PlayerService.refreshLives(id);
    final currentLevelIndex = await PlayerService.getCurrentLevel();

    try {
      final levels = await LevelService.fetchAllLevels();

      if (levels.isEmpty) {
        showError('Нет доступных уровней');
        return;
      }

      final levelIndex = (currentLevelIndex ?? 0).clamp(0, levels.length - 1);
      final startingLevel = levels[levelIndex];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuScreen(
            levels: levels,
            currentLevel: startingLevel,
          ),
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (playerId != null)
              Text('ID игрока: $playerId', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
