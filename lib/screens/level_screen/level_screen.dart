import 'package:flutter/material.dart';

import '../../servises/models/level.dart';
import 'level_widgets/PhraseDisplayWidget.dart';
import 'level_widgets/VirtualKeyboardWidget.dart';

class LevelScreen extends StatefulWidget {
  final Level level;
  const LevelScreen({super.key, required this.level});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late List<int> revealed;
  late List<String?> userInput;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    revealed = List<int>.from(widget.level.revealed);
    userInput = List<String?>.filled(widget.level.quote.length, null);
  }

  void onLetterPressed(String letter) {
    if (selectedIndex != null && !revealed.contains(selectedIndex)) {
      setState(() {
        userInput[selectedIndex!] = letter;
        selectedIndex = null; // сбрасываем выбор
      });
    }
  }

  void onSelectCell(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;

    return Scaffold(
      appBar: AppBar(title: Text('Уровень ${level.id}')),
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
