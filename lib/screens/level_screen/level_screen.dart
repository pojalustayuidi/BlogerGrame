  import 'package:blogergrame/screens/level_screen/level_widgets/custom_level_appbar_widget.dart';
  import 'package:blogergrame/screens/menu_screen/menu_screen.dart';
  import 'package:flutter/material.dart';
  import '../../servises/models/level.dart';
  import '../../servises/player_sevice.dart';
  import 'level_widgets/phrase_display_widget.dart';
  import 'level_widgets/virtual_keyboard_widget.dart';
  import 'dart:async';
  import 'level_widgets/level_compite_dialog.dart';
  
  class LevelScreen extends StatefulWidget {
    final Level currentLevel;
    final List<Level> allLevels;
  
    const LevelScreen(
        {super.key, required this.currentLevel, required this.allLevels});
  
    @override
    State<LevelScreen> createState() => _LevelScreenState();
  }
  
  class _LevelScreenState extends State<LevelScreen> {
    DateTime? _startTime;
    late List<int> revealed;
    late List<String?> userInput;
    int? selectedIndex;
    List<int> incorrectIndices = [];
    List<int> correctIndices = [];
    List<int> completedNumbers = [];
    int errorCount = 0; // Счётчик ошибок
    int serverLives = 5; // Жизни с сервера
    bool hasLost = false;
    bool _isSavingProgress = false;
    bool _isProcessingLoss = false;
  
    @override
    void initState() {
      super.initState();
      revealed = List<int>.from(widget.currentLevel.revealed);
      userInput = List<String?>.filled(widget.currentLevel.quote.length, null);
      _startTime = DateTime.now();
      _loadPlayerStatus();
    }
  
    Future<void> _loadPlayerStatus() async {
      try {
        final status = await PlayerService.getStatus();
        if (status != null && mounted) {
          setState(() {
            serverLives = status['lives'] ?? 5;
          });
          print('Статус игрока загружен: serverLives=$serverLives');
        }
      } catch (e) {
        print('Ошибка загрузки статуса: $e');
      }
    }
  
    bool _isNumberCompleted(int number) {
      final indices = widget.currentLevel.quote
          .split('')
          .asMap()
          .entries
          .where((e) =>
              widget.currentLevel.letterMap[e.value.toLowerCase()] == number)
          .map((e) => e.key)
          .toList();
  
      return indices.every((index) {
        final correctChar = widget.currentLevel.quote[index].toLowerCase();
        final input = userInput[index]?.toLowerCase();
        final revealed = widget.currentLevel.revealed.contains(index);
        return revealed || (input != null && input == correctChar);
      });
    }
  
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  
    Future<void> checkIfLevelCompleted() async {
      if (_isSavingProgress) return;
      final phrase = widget.currentLevel.quote;
      final revealed = widget.currentLevel.revealed;
      final input = userInput;
  
      final buffer = StringBuffer();
      final expectedBuffer = StringBuffer();
  
      for (int i = 0; i < phrase.length; i++) {
        final char = phrase[i];
        if (char == ' ') continue;
        expectedBuffer.write(char.toLowerCase());
        if (revealed.contains(i)) {
          buffer.write(char.toLowerCase());
        } else {
          final userChar = input[i];
          if (userChar == null || userChar.isEmpty) return;
          buffer.write(userChar.toLowerCase());
        }
      }
  
      final expected = expectedBuffer.toString();
      final actual = buffer.toString();
  
      if (expected == actual) {
        _isSavingProgress = true;
        final reward = widget.currentLevel.reward;
        final progressResult = await PlayerService.updateProgress(
          widget.currentLevel.id + 1,
          reward,
        );

        if (progressResult!['success']) {
          print('Ошибка при обновлении прогресса');
        }
        if (mounted) {
          final duration = DateTime.now().difference(_startTime!);
          final formattedTime = formatDuration(duration);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => LevelCompletedDialog(
              levelNumber: widget.currentLevel.id,
              currentLevel: widget.currentLevel,
              allLevels: widget.allLevels,
              formattedTime: formattedTime, rewards: reward, coinsAdded: progressResult['coinsAdded']  ?? reward,
              newcoins: progressResult['newCoins'] ?? 0,
            ),
          );
        }
        _isSavingProgress = false;
      }
    }
  
    void _updateCompletedNumbers() {
      final uniqueNumbers = widget.currentLevel.letterMap.values.toSet();
      completedNumbers =
          uniqueNumbers.where((number) => _isNumberCompleted(number)).toList();
    }
  
    void _moveToNextAvailableCell() {
      if (selectedIndex == null) return;
      for (int i = selectedIndex! + 1; i < userInput.length; i++) {
        if (!revealed.contains(i) && !correctIndices.contains(i)) {
          setState(() {
            selectedIndex = i;
          });
          return;
        }
      }
      for (int i = 0; i < selectedIndex!; i++) {
        if (!revealed.contains(i) && !correctIndices.contains(i)) {
          setState(() {
            selectedIndex = i;
          });
          return;
        }
      }
      setState(() {
        selectedIndex = null;
      });
    }
  
    Future<void> _handleLoss() async {
      if (_isProcessingLoss || hasLost) return;
      _isProcessingLoss = true;
  
      try {
        final success = await PlayerService.decrementLives();
        if (success) {
          await _loadPlayerStatus();
          if (mounted) {
            setState(() => hasLost = true);
            showDialog(
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
                      Text(serverLives <= 0
                          ? 'У вас закончились жизни.'
                          : 'Вы сделали 5 ошибок.'),
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
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => LevelScreen(
                                    currentLevel: widget.currentLevel,
                                    allLevels: widget.allLevels,
                                  ),
                                ),
                              );
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
        } else {
          print('Ошибка при уменьшении жизни');
        }
      } catch (e) {
        print('Ошибка при обработке проигрыша: $e');
      } finally {
        _isProcessingLoss = false;
      }
    }
  
    void onLetterPressed(String letter, void Function() onLetterAccepted) {
      if (selectedIndex == null ||
          selectedIndex! >= userInput.length ||
          revealed.contains(selectedIndex!) ||
          correctIndices.contains(selectedIndex!)) return;
  
      // Изменяем локальный ввод и подсчёт ошибок в setState
      setState(() {
        userInput[selectedIndex!] = letter;
      });
  
      final correctChar = widget.currentLevel.quote[selectedIndex!].toLowerCase();
      final letterLower = letter.toLowerCase();
  
      if (letterLower != correctChar) {
        setState(() {
          incorrectIndices.add(selectedIndex!);
          errorCount++;
        });
        print('Ошибка №$errorCount');
  
        if (errorCount >= 5) {
          _handleLoss();
          return;
        }
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              userInput[selectedIndex!] = null;
              incorrectIndices.remove(selectedIndex!);
            });
          }
        });
      } else {
        setState(() {
          incorrectIndices.remove(selectedIndex!);
          correctIndices.add(selectedIndex!);
        });
        final number = widget.currentLevel.letterMap[correctChar];
        _updateCompletedNumbers();
        if (number != null && completedNumbers.contains(number)) {
          onLetterAccepted();
        }
        checkIfLevelCompleted();
        _moveToNextAvailableCell();
      }
    }
  
    void onSelectCell(int index) {
      if (index < 0 || index >= userInput.length) return;
      if (!revealed.contains(index) && !correctIndices.contains(index)) {
        setState(() {
          selectedIndex = (selectedIndex == index) ? null : index;
        });
      }
    }
  
    @override
    Widget build(BuildContext context) {
      final level = widget.currentLevel;
  
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFFBE9D0),
          appBar: CustomLevelAppBar(
              levelId: level.id,
              errorCount: errorCount,
              allLevels: widget.allLevels,
              currentLevel: widget.currentLevel),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: PhraseDisplayWidget(
                      level: level,
                      userInput: userInput,
                      selectedIndex: selectedIndex,
                      incorrectIndices: incorrectIndices,
                      correctIndices: correctIndices,
                      completedNumbers: completedNumbers,
                      onSelect: onSelectCell,
                    ),
                  ),
                ),
                const Divider(),
                VirtualKeyboardWidget(
                  onLetterPressed: onLetterPressed,
                  correctIndices: correctIndices,
                  revealed: revealed,
                  letterMap: level.letterMap,
                  userInput: userInput,
                  fullPhrase: level.quote,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
