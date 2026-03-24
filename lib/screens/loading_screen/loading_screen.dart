
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/level_provider.dart';

import '../menu_screen/menu_screen.dart';


class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoadingStatus();
    });
  }

  void _checkLoadingStatus() {
    final playerState = ref.read(playerProvider);
    final levelsState = ref.read(levelsProvider);

    if (playerState.hasValue && levelsState.hasValue) {
      _navigateToMenu();
    }
  }

  void _navigateToMenu() {
    if (_navigated) return;
    _navigated = true;

    final player = ref.read(playerProvider).value!;
    final levels = ref.read(levelsProvider).value!;

    final currentLevel = levels.firstWhere(
          (level) => level.id == player.currentLevel,
      orElse: () => levels.first,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          levels: levels,
          currentLevel: currentLevel,
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              ref.invalidate(playerProvider);
              ref.invalidate(levelsProvider);

              setState(() {
                _navigated = false;
              });
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final playerAsync = ref.watch(playerProvider);
    final levelsAsync = ref.watch(levelsProvider);

    if (playerAsync.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError('Ошибка игрока: ${playerAsync.error}');
      });
    } else if (levelsAsync.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError('Ошибка уровней: ${levelsAsync.error}');
      });
    }

    if (playerAsync.hasValue && levelsAsync.hasValue && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToMenu();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF1A1F2F),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),

              const SizedBox(height: 32),

              const Text(
                'Криптограмма',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),


              playerAsync.when(
                data: (player) => Text(
                  'Игрок: ${player.id.substring(0, 8)}...',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
                error: (error, stack) => const Text(
                  'Ошибка игрока',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                loading: () => const Text(
                  'Загрузка игрока...',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),

              const SizedBox(height: 8),

              levelsAsync.when(
                data: (levels) => Text(
                  'Уровней: ${levels.length}',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
                error: (error, stack) => const Text(
                  'Ошибка уровней',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                loading: () => const Text(
                  'Загрузка уровней...',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}