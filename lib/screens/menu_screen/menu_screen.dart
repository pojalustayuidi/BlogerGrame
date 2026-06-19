import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/life_timer_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/models/level.dart';
import '../level_screen/level_screen.dart';
import '../store_screen/shope_screen.dart';
import 'menu_widgets/buttons.dart';
import 'menu_widgets/topbar_ui_wdiget.dart';

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
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -40,
                right: -40,
                child: Container(
                  height: 260,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                      bottomRight: Radius.circular(48),
                    ),
                  ),
                ),
              ),
              playerAsync.when(
                data: (player) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: MenuTopBar(
                        lives: player.lives,
                        coins: player.coins,
                        maxLives: 5,
                        timeUntilNextLife: timeToNextLife,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MenuHeroCard(
                        currentLevel: currentLevel,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: MenuButtons(
                          lives: player.lives,
                          currentLevel: currentLevel,
                          levels: levels,
                          onPressedContinue: () async {
                            if (player.lives > 0) {
                              final success = await ref
                                  .read(playerProvider.notifier)
                                  .decrementLives();

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
                                  const SnackBar(
                                    content: Text('Ошибка при запуске уровня'),
                                  ),
                                );
                              }
                            }
                          },
                          showNoLivesDialog: () => _showNoLivesDialog(context),
                          loadStatus: () {
                            ref.invalidate(playerProvider);
                          },
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Версия 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 52,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Не удалось загрузить меню',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(playerProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B8DEF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Жизни закончились',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'У вас закончились жизни. Дождитесь восстановления или купите жизни в магазине.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('В магазин'),
          ),
        ],
      ),
    );
  }
}

class _MenuHeroCard extends StatelessWidget {
  final Level currentLevel;

  const _MenuHeroCard({
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Color(0xFF5B8DEF),
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Готов продолжить?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сейчас доступен уровень ${currentLevel.id}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}