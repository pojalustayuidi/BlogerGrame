import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/models/level.dart';
import 'level_widgets/custom_level_appbar_widget.dart';
import 'level_widgets/hint_counter_widget.dart';
import 'level_widgets/level_compite_dialog.dart';
import 'level_widgets/phrase_display_widget.dart';
import 'level_widgets/virtual_keyboard_widget.dart';
import '../menu_screen/menu_screen.dart';

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

class _LevelScreenState extends ConsumerState<LevelScreen> {
  final GlobalKey<HintCounterWidgetState> _hintKey = GlobalKey();

  bool _isWinDialogShown = false;
  bool _isLossDialogShown = false;

  @override
  void initState() {
    super.initState();
    _isWinDialogShown = false;
    _isLossDialogShown = false;
  }

  @override
  void didUpdateWidget(covariant LevelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если уровень изменился - сбрасываем флаги
    if (oldWidget.currentLevel.id != widget.currentLevel.id) {
      _isWinDialogShown = false;
      _isLossDialogShown = false;
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем состояние игры
    final game = ref.watch(gameProvider(widget.currentLevel));
    final player = ref.watch(playerProvider).valueOrNull;

    if (game.isCompleted && !_isWinDialogShown) {
      // Сразу ставим флаг, чтобы не показывать снова
      _isWinDialogShown = true;

      final duration = DateTime.now().difference(game.startTime);
      final formattedTime = formatDuration(duration);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LevelCompletedDialog(
            levelNumber: game.level.id,
            currentLevel: game.level,
            allLevels: widget.allLevels,
            formattedTime: formattedTime,
            rewards: game.level.reward,
            coinsAdded: game.level.reward,
            newcoins: (player?.coins ?? 0) + game.level.reward,
          ),
        ).then((_) {
          // После закрытия диалога сбрасываем флаг
          _isWinDialogShown = false;
        });
      });
    }

    if (game.isLost && !_isLossDialogShown) {
      // Сразу ставим флаг
      _isLossDialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _showLossDialog().then((_) {
          _isLossDialogShown = false;
        });
      });
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBE9D0),
        appBar: CustomLevelAppBar(
          levelId: game.level.id,
          errorCount: game.errorCount,
          allLevels: widget.allLevels,
          currentLevel: game.level,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Поле с фразой
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PhraseDisplayWidget(
                    level: game.level,
                    userInput: game.userInput,
                    selectedIndex: game.selectedIndex,
                    incorrectIndices: game.incorrectIndices,
                    correctIndices: game.correctIndices,
                    completedNumbers: game.completedNumbers,
                    onSelect: (index) {
                      ref.read(gameProvider(widget.currentLevel).notifier)
                          .selectCell(index);
                    },
                  ),
                ),
              ),

              // Подсказки
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: HintCounterWidget(
                      key: _hintKey,
                      onPressed: () async {
                        final success = await ref.read(
                            gameProvider(widget.currentLevel).notifier
                        ).useHint();

                        if (success) {
                          _hintKey.currentState?.refresh();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Недостаточно подсказок'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const Divider(),

              // Клавиатура
              VirtualKeyboardWidget(
                onLetterPressed: (letter, onAccepted) {
                  ref.read(gameProvider(widget.currentLevel).notifier)
                      .pressLetter(letter);
                },
                correctIndices: game.correctIndices,
                revealed: game.revealed,
                letterMap: game.level.letterMap,
                userInput: game.userInput,
                fullPhrase: game.level.quote,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLossDialog() async {
    final playerLives = ref.read(playerProvider).valueOrNull?.lives ?? 0;
    final game = ref.read(gameProvider(widget.currentLevel));

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Center(child: Text('Вы проиграли')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.sentiment_very_dissatisfied, size: 48),
              const SizedBox(height: 16),
              Text(
                playerLives <= 0
                    ? 'У вас закончились жизни.'
                    : 'Вы сделали 5 ошибок.',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home, size: 32),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => MenuScreen(
                            levels: widget.allLevels,
                            currentLevel: widget.currentLevel,
                          ),
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Сбрасываем уровень
                      ref.read(gameProvider(widget.currentLevel).notifier)
                          .resetLevel();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Переиграть'),
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