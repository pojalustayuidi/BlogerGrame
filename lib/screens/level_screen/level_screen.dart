import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/models/level.dart';
import '../menu_screen/menu_screen.dart';
import '../store_screen/shope_screen.dart';
import 'level_widgets/custom_level_appbar_widget.dart';
import 'level_widgets/level_compite_dialog.dart';
import 'level_widgets/phrase_board_card.dart';
import 'level_widgets/virtual_keyboard_widget.dart';

class LevelScreen extends ConsumerStatefulWidget {
  final Level currentLevel;
  final List<Level> allLevels;

  const LevelScreen({
    super.key,
    required this.currentLevel,
    required this.allLevels,
  });

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen>
    with SingleTickerProviderStateMixin {
  bool _isWinDialogShown = false;
  bool _isLossDialogShown = false;

  // Анимация появления экрана
  late final AnimationController _enterController;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _enterFade = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );

    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    ));

    _enterController.forward();
  }

  @override
  void didUpdateWidget(covariant LevelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel.id != widget.currentLevel.id) {
      _isWinDialogShown = false;
      _isLossDialogShown = false;
      _enterController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Использование подсказки
  Future<void> _useHint() async {
    final game = ref.read(gameProvider(widget.currentLevel));
    if (game.selectedIndex == null) {
      _showToast('Сначала выберите ячейку');
      return;
    }

    final player = ref.read(playerProvider).valueOrNull;
    if (player == null) return;

    if (player.hints <= 0) {
      _showNoHintsDialog();
      return;
    }

    final success = await ref
        .read(gameProvider(widget.currentLevel).notifier)
        .useHint();

    if (!success && mounted) {
      _showToast('Не удалось использовать подсказку');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNoHintsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Нет подсказок',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Купите подсказки в магазине.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
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
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('В магазин'),
          ),
        ],
      ),
    );
  }

  Future<void> _goHome() async {
    ref.invalidate(gameProvider(widget.currentLevel));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          levels: widget.allLevels,
          currentLevel: widget.currentLevel,
        ),
      ),
    );
  }

  Future<void> _retryLevel() async {
    ref.read(gameProvider(widget.currentLevel).notifier).resetLevel();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showLossDialog(int playerLives) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                  color: Colors.black.withOpacity(0.12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Шапка в стиле проекта
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.heart_broken_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Вы проиграли',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Попробуйте ещё раз',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Тело диалога
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                playerLives <= 0
                                    ? 'У вас закончились жизни.\nЗайдите в магазин.'
                                    : '5 ошибок подряд.\nБудьте внимательнее!',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _goHome,
                                icon: const Icon(Icons.home_rounded, size: 18),
                                label: const Text('Меню'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF374151),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                        color: Color(0xFFE5E7EB)),
                                  ),
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _retryLevel,
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 18),
                                label: const Text('Заново'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF5B8DEF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen вынесен в build — это правильно для ConsumerStatefulWidget
    ref.listen<GameState>(
      gameProvider(widget.currentLevel),
          (previous, next) {
        if (!mounted) return;

        // Победа
        if (previous?.isCompleted != true &&
            next.isCompleted &&
            !_isWinDialogShown) {
          _isWinDialogShown = true;

          // Обновляем монеты в playerProvider
          final player = ref.read(playerProvider).valueOrNull;
          if (player != null) {
            ref
                .read(playerProvider.notifier)
                .updateCoins(player.coins + next.level.reward);
          }

          final duration = DateTime.now().difference(next.startTime);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => LevelCompletedDialog(
                levelNumber: next.level.id,
                currentLevel: next.level,
                allLevels: widget.allLevels,
                formattedTime: _formatDuration(duration),
                rewards: next.level.reward,
                coinsAdded: next.level.reward,
                newcoins: (player?.coins ?? 0) + next.level.reward,
              ),
            ).then((_) => _isWinDialogShown = false);
          });
        }

        // Поражение
        if (previous?.isLost != true &&
            next.isLost &&
            !_isLossDialogShown) {
          _isLossDialogShown = true;
          final lives = ref.read(playerProvider).valueOrNull?.lives ?? 0;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showLossDialog(lives).then((_) => _isLossDialogShown = false);
          });
        }
      },
    );

    final game = ref.watch(gameProvider(widget.currentLevel));
    final player = ref.watch(playerProvider).valueOrNull;
    final hints = player?.hints ?? 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: CustomLevelAppBar(
          levelId: game.level.id,
          errorCount: game.errorCount,
          allLevels: widget.allLevels,
          currentLevel: game.level,
          hints: hints,
          onHintPressed: _useHint,
        ),
        body: FadeTransition(
          opacity: _enterFade,
          child: SlideTransition(
            position: _enterSlide,
            child: Stack(
              children: [
                // Синий фон сверху
                Positioned(
                  top: -90,
                  left: -24,
                  right: -24,
                  child: Container(
                    height: 190,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          child: PhraseBoardCard(
                            level: game.level,
                            userInput: game.userInput,
                            selectedIndex: game.selectedIndex,
                            incorrectIndices: game.incorrectIndices,
                            correctIndices: game.correctIndices,
                            completedNumbers: game.completedNumbers,
                            onSelect: (index) => ref
                                .read(gameProvider(widget.currentLevel).notifier)
                                .selectCell(index),
                          ),
                        ),
                      ),
                      VirtualKeyboardWidget(
                        onLetterPressed: (letter, onAccepted) => ref
                            .read(gameProvider(widget.currentLevel).notifier)
                            .pressLetter(letter),
                        correctIndices: game.correctIndices,
                        revealed: game.revealed,
                        letterMap: game.level.letterMap,
                        userInput: game.userInput,
                        fullPhrase: game.level.quote,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}