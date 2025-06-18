import 'package:flutter/material.dart';
import '../../../servises/models/level.dart';
import 'phrase_cell.dart';

class PhraseDisplayWidget extends StatelessWidget {
  final Level level;
  final List<String?> userInput;
  final int? selectedIndex;
  final List<int> incorrectIndices;
  final List<int> correctIndices;
  final List<int> completedNumbers;
  final void Function(int index) onSelect;

  const PhraseDisplayWidget({
    super.key,
    required this.level,
    required this.userInput,
    required this.selectedIndex,
    required this.incorrectIndices,
    required this.correctIndices,
    required this.completedNumbers,
    required this.onSelect,
  });


  @override
  Widget build(BuildContext context) {
    final chars = level.quote.split('');
    List<Widget> lines = [];
    List<Widget> currentLine = [];
    List<Widget> currentWord = [];

    int globalIndex = 0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (char == ' ') {
        if (currentWord.isNotEmpty) {
          currentLine.addAll(currentWord);
          currentWord.clear();
        }
        currentLine.add(const SizedBox(width: 12));
        globalIndex++;
        continue;
      }

      final isPunctuation = char == ',' || char == '.';
      final isRevealed = level.revealed.contains(globalIndex) || isPunctuation;
      final letter = char.toLowerCase();
      final number = level.letterMap[letter];
      final value = isRevealed ? char : userInput[globalIndex];
      final cellIndex = globalIndex;

      final cell = PhraseCell(
        index: cellIndex,
        value: value,
        number: number,
        isRevealed: isRevealed,
        isSelected: selectedIndex == cellIndex,
        isIncorrect: incorrectIndices.contains(cellIndex),
        isCorrect: correctIndices.contains(cellIndex),
        isCompleted: completedNumbers.contains(number),
        onTap: () => onSelect(cellIndex),
      );

      currentWord.add(cell);

      final isEndOfWord = i == chars.length - 1 ||
          chars[i + 1] == ' ' ||
          chars[i + 1] == ',' ||
          chars[i + 1] == '.';

      if (isEndOfWord) {
        // estimate width
        final estimatedWidth = currentLine.length + currentWord.length;
        if (estimatedWidth > 12) {
          lines.add(Wrap(spacing: 6, runSpacing: 6, children: currentLine));
          currentLine = [];
        }
        currentLine.addAll(currentWord);
        currentWord.clear();
      }

      globalIndex++;
    }

    if (currentLine.isNotEmpty) {
      lines.add(Wrap(spacing: 6, runSpacing: 6, children: currentLine));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: line,
      ))
          .toList(),
    );
  }
}
