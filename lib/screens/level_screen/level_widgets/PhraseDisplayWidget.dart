import 'package:flutter/material.dart';
import '../../../servises/models/level.dart';
import 'phrase_cell.dart';

class PhraseDisplayWidget extends StatelessWidget {
  final Level level;
  final List<String?> userInput;
  final int? selectedIndex;
  final List<int> incorrectIndices;
  final List<int> completedNumbers;
  final void Function(int index) onSelect;

  const PhraseDisplayWidget({
    super.key,
    required this.level,
    required this.userInput,
    required this.selectedIndex,
    required this.incorrectIndices,
    required this.completedNumbers,
    required this.onSelect,
  });

  bool _isLetter(String char) {
    return RegExp(r'[а-яА-ЯёЁ]').hasMatch(char);
  }

  @override
  Widget build(BuildContext context) {
    final chars = level.quote.split('');
    final List<Widget> rows = [];
    final List<Widget> widgets = [];
    int globalIndex = 0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      if (globalIndex >= userInput.length) break;

      if (char == ' ') {
        widgets.add(const SizedBox(width: 8));
        globalIndex++;
        continue;
      }

      final isPunctuation = char == ',' || char == '.';
      final isRevealed = level.revealed.contains(globalIndex) || isPunctuation;
      final letter = char.toLowerCase();
      final number = level.letterMap[letter];
      final value = isRevealed ? char : userInput[globalIndex];
      final cellIndex = globalIndex;

      if (_isLetter(char) || isPunctuation) {
        widgets.add(
          PhraseCell(
            index: cellIndex,
            value: value,
            number: number,
            isRevealed: isRevealed,
            isSelected: selectedIndex == cellIndex,
            isIncorrect: incorrectIndices.contains(cellIndex),
            isCompleted: completedNumbers.contains(number),
            onTap: () => onSelect(cellIndex),
          ),
        );
      }

      if (char == ',' || char == '.' || char == ' ' || i == chars.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Wrap(
              children: [...widgets],
            ),
          ),
        );
        if (char != ' ') {
          widgets.clear();
        }
      }

      globalIndex++;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}