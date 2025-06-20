import 'package:flutter/material.dart';
import '../../../servises/models/level.dart';
import '../../menu_screen/menu_screen.dart';
import '../level_screen.dart';

class LevelCompletedDialog extends StatelessWidget {
  final int levelNumber;
  final Level currentLevel;
  final List<Level> allLevels;
  final String? formattedTime;

  const LevelCompletedDialog({
    super.key,
    required this.levelNumber,
    required this.currentLevel,
    required this.allLevels, this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // блокируем кнопку "Назад"
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Уровень $levelNumber пройден!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '“${currentLevel.quote}”',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '- ${currentLevel.author}',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
              if (formattedTime != null) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Время прохождения: $formattedTime',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final nextIndex = allLevels.indexOf(currentLevel) + 1;
                      final nextLevel = (nextIndex < allLevels.length)
                          ? allLevels[nextIndex]
                          : currentLevel;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MenuScreen(
                            levels: allLevels,
                            currentLevel: nextLevel,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Главное меню'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final nextIndex = allLevels.indexOf(currentLevel) + 1;
                      if (nextIndex < allLevels.length) {
                        final nextLevel = allLevels[nextIndex];
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => LevelScreen(
                              currentLevel: nextLevel,
                              allLevels: allLevels,
                            ),
                          ),
                        );
                      } else {
                        // если это последний уровень — вернуться в меню
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MenuScreen(
                              levels: allLevels,
                              currentLevel: currentLevel,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Далее'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
