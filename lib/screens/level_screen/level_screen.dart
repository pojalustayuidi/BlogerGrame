import 'package:flutter/material.dart';
import '../../servises/models/level.dart';
import 'level_widgets/PhraseDisplayWidget.dart';
import 'level_widgets/VirtualKeyboardWidget.dart';
import 'dart:async';

class LevelScreen extends StatefulWidget {
  final Level level;
  const LevelScreen({super.key, required this.level});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  List<int> revealed = [];
  List<String?> userInput = [];
  int? selectedIndex;
  List<int> incorrectIndices = [];
  List<int> completedNumbers = [];

  @override
  void initState() {
    super.initState();
    revealed = List<int>.from(widget.level.revealed);
    userInput = List<String?>.filled(widget.level.quote.length, null);
  }

  bool _isNumberCompleted(int number) {
    final indices = widget.level.quote
        .split('')
        .asMap()
        .entries
        .where((e) => widget.level.letterMap[e.value.toLowerCase()] == number)
        .map((e) => e.key)
        .toList();
    return indices.every((index) =>
    userInput[index] != null &&
        userInput[index]!.toLowerCase() == widget.level.quote[index].toLowerCase());
  }

  void _updateCompletedNumbers() {
    final uniqueNumbers = widget.level.letterMap.values.toSet();
    completedNumbers = uniqueNumbers
        .where((number) => _isNumberCompleted(number))
        .toList();
  }

  void onLetterPressed(String letter) {
    if (selectedIndex == null) return;
    if (selectedIndex! >= userInput.length || selectedIndex! < 0) return;
    if (revealed.contains(selectedIndex)) return;

    setState(() {
      userInput[selectedIndex!] = letter;
      final correctChar = widget.level.quote[selectedIndex!].toLowerCase();
      if (letter != correctChar) {
        incorrectIndices.add(selectedIndex!);
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              userInput[selectedIndex!] = null;
              incorrectIndices.remove(selectedIndex!);
            });
          }
        });
      } else {
        incorrectIndices.remove(selectedIndex!);
        _updateCompletedNumbers();
      }
    });
  }

  void onSelectCell(int index) {
    if (index < 0 || index >= userInput.length) return;
    if (!revealed.contains(index)) {
      setState(() {
        selectedIndex = (selectedIndex == index) ? null : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;

    return Scaffold(
      appBar: AppBar(title: Text('Level ${level.id}')),
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
                  completedNumbers: completedNumbers,
                  onSelect: onSelectCell,
                ),
              ),
            ),
            const Divider(),
            VirtualKeyboardWidget(onLetterPressed: onLetterPressed),
          ],
        ),
      ),
    );
  }
}