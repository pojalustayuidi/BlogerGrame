import 'package:blogergrame/screens/level_screen/level_widgets/lives_widget.dart';
import 'package:blogergrame/screens/menu_screen/menu_screen.dart';
import 'package:flutter/material.dart';
import '../../servises/models/level.dart';
import 'level_widgets/PhraseDisplayWidget.dart';
import 'level_widgets/VirtualKeyboardWidget.dart';
import 'dart:async';
import 'level_widgets/level_compite_dialog.dart';

class LevelScreen extends StatefulWidget {
  final Level currentLevel;
  final List<Level> allLevels;

  const LevelScreen({super.key, required this.currentLevel, required this.allLevels});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  List<int> revealed = [];
  List<String?> userInput = [];
  int? selectedIndex;
  List<int> incorrectIndices = [];
  List<int> correctIndices = [];
  List<int> completedNumbers = [];
  int lives = 5;
  bool hasLost = false;

  @override
  void initState() {
    super.initState();
    revealed = List<int>.from(widget.currentLevel.revealed);
    userInput = List<String?>.filled(widget.currentLevel.quote.length, null);
  }

  bool _isNumberCompleted(int number) {
    final indices = widget.currentLevel.quote
        .split('')
        .asMap()
        .entries
        .where((e) => widget.currentLevel.letterMap[e.value.toLowerCase()] == number)
        .map((e) => e.key)
        .toList();

    return indices.every((index) {
      final correctChar = widget.currentLevel.quote[index].toLowerCase();
      final input = userInput[index]?.toLowerCase();
      final revealed = widget.currentLevel.revealed.contains(index);

      return revealed || (input != null && input == correctChar);
    });
  }

  void checkIfLevelCompleted() {
    final phrase = widget.currentLevel.quote.toLowerCase();
    final current = userInput.map((e) => (e ?? '')).join().toLowerCase();

    if (phrase == current) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => LevelCompleteDialog(
          author: widget.currentLevel.author,
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  void _updateCompletedNumbers() {
    final uniqueNumbers = widget.currentLevel.letterMap.values.toSet();
    completedNumbers = uniqueNumbers
        .where((number) => _isNumberCompleted(number))
        .toList();
  }

  void _moveToNextAvailableCell() {
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

  void onLetterPressed(String letter, void Function() onLetterAccepted) {
    if (selectedIndex == null ||
        selectedIndex! >= userInput.length ||
        revealed.contains(selectedIndex!) ||
        correctIndices.contains(selectedIndex!)) return;

    setState(() {
      userInput[selectedIndex!] = letter;
      final correctChar = widget.currentLevel.quote[selectedIndex!].toLowerCase();
      final letterLower = letter.toLowerCase();
      if (letterLower != correctChar) {
        incorrectIndices.add(selectedIndex!);
        lives--;

        if (lives <= 0 && !hasLost) {
          hasLost = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Center(child: Text('Вы совершили 5 ошибок')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.sentiment_very_dissatisfied, size: 48),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.home, size: 32),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) =>
                                  MenuScreen(levels: widget.allLevels,
                                      currentLevel: widget.currentLevel)));
                        } ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LevelScreen(currentLevel: widget.currentLevel, allLevels: widget.allLevels,),
                              ),
                            );
                          },
                          child: const Text('Переиграть'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        } else {
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                userInput[selectedIndex!] = null;
                incorrectIndices.remove(selectedIndex!);
              });
            }
          });
        }
      } else {
        incorrectIndices.remove(selectedIndex!);
        correctIndices.add(selectedIndex!);
        final number = widget.currentLevel.letterMap[correctChar];
        _updateCompletedNumbers();
        if (number != null && completedNumbers.contains(number)) {
          onLetterAccepted();
        }
        checkIfLevelCompleted();
        _moveToNextAvailableCell();
      }
    });
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MenuScreen(levels: widget.allLevels, currentLevel: widget.currentLevel,)),
            );
          },
        ),
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LivesDisplayWidget(lives: lives),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 20,
                child: Text(
                  'Level ${level.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    );
  }
}
