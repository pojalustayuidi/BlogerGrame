import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../providers/life_timer_provider.dart';
import '../../services/models/level.dart';
import '../level_screen/level_screen.dart';
import '../store_screen/shope_screen.dart';
import 'menu_widgets/topbar_ui_wdiget.dart';
import 'menu_widgets/buttons.dart';

class MenuScreen extends ConsumerWidget {
  final List<Level> levels;
  final Level currentLevel;

  const MenuScreen({
    super.key,
    required this.levels,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);

    final timeToNextLife = ref.watch(lifeTimerProvider);



    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(

                ),
              ),
              playerAsync.when(
                data: (player) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: TopBar(
                        lives: player.lives,
                        coins: player.coins,
                        maxLives: 5,
                        timeUntilNextLife: timeToNextLife,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Buttons(
                      lives: player.lives,
                      currentLevel: currentLevel,
                      levels: levels,
                      onPressedContinue: () async {
                        if (player.lives > 0) {
                          final success = await ref.read(playerProvider.notifier).decrementLives();

                          if (success) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LevelScreen(
                                  currentLevel: currentLevel,
                                  allLevels: levels,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ошибка при запуске уровня')),
                            );
                          }
                        }
                      },
                      showNoLivesDialog: () => _showNoLivesDialog(context),
                      loadStatus: () {
                        ref.invalidate(playerProvider);
                      },
                    ),
                    const Spacer(flex: 1),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Версия 1.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: ElevatedButton(
                    onPressed: () => ref.invalidate(playerProvider),
                    child: const Text('Попробовать снова'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showNoLivesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Жизни закончились'),
        content: const Text(
          'У вас закончились жизни. Дождитесь восстановления или купите жизни в магазине.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
            child: const Text('В магазин'),
          ),
        ],
      ),
    );
  }
}