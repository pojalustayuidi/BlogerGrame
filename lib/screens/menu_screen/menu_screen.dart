import 'package:flutter/material.dart';
import '../../servises/models/level.dart';
import '../level_screen/level_screen.dart';

class MenuScreen extends StatelessWidget {
  final List<Level> levels;
  final Level currentLevel;

  const MenuScreen({
    super.key,
    required this.levels,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // запрет на выход по "назад"
      child: SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Добро пожаловать!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Продолжить с ${currentLevel.id} уровня'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelScreen(
                          currentLevel: currentLevel,
                          allLevels: levels,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Магазин'),
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Настройки'),
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const Spacer(),
                const Text(
                  'Версия 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
