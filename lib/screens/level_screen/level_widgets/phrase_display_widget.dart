import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../services/models/level.dart';
import 'phrase_cell.dart';

class PhraseDisplayWidget extends StatelessWidget {
  final Level level;
  final List<String?> userInput;
  final int? selectedIndex;
  final List<int> incorrectIndices;
  final List<int> correctIndices;
  final List<int> completedNumbers;
  final void Function(int index) onSelect;
  // Точная доступная ширина, переданная из PhraseBoardCard через LayoutBuilder
  final double availableWidth;

  const PhraseDisplayWidget({
    super.key,
    required this.level,
    required this.userInput,
    required this.selectedIndex,
    required this.incorrectIndices,
    required this.correctIndices,
    required this.completedNumbers,
    required this.onSelect,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final wordsData = _buildWordsDataFromPhrase(level.quote);

    final longestWordLength = wordsData.isEmpty
        ? 1
        : wordsData
        .map((word) => word.length)
        .reduce((a, b) => a > b ? a : b);

    const innerSpacing = 4.0;

    // Считаем размер ячейки от доступной ширины — теперь она точная
    final cellWidthByLongestWord =
        (availableWidth - (math.max(0, longestWordLength - 1) * innerSpacing)) /
            math.max(1, longestWordLength);

    final cellSize = cellWidthByLongestWord.clamp(24.0, 40.0);
    final wordSpacing = (cellSize * 0.22).clamp(8.0, 12.0);
    final lineSpacing = (cellSize * 0.24).clamp(10.0, 14.0);

    final wordWidgets = wordsData.map((word) {
      return _PhraseWord(
        spacing: innerSpacing,
        children: word.map((cellData) {
          return PhraseCell(
            index: cellData.index,
            value: cellData.value,
            number: cellData.number,
            isRevealed: cellData.isRevealed,
            isSelected: selectedIndex == cellData.index,
            isIncorrect: incorrectIndices.contains(cellData.index),
            isCorrect: correctIndices.contains(cellData.index),
            isCompleted: completedNumbers.contains(cellData.number),
            onTap: () => onSelect(cellData.index),
            cellSize: cellSize,
          );
        }).toList(),
      );
    }).toList();

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: wordSpacing,
        runSpacing: lineSpacing,
        children: wordWidgets,
      ),
    );
  }

  List<List<_CellData>> _buildWordsDataFromPhrase(String phrase) {
    final words = <List<_CellData>>[];
    final splitWords = phrase.split(' ');
    int globalIndex = 0;

    for (final word in splitWords) {
      final cells = <_CellData>[];

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        final isPunctuation = char == ',' || char == '.';
        final isRevealed =
            level.revealed.contains(globalIndex) || isPunctuation;
        final letter = char.toLowerCase();
        final number = level.letterMap[letter];
        final value = isRevealed ? char : userInput[globalIndex];

        cells.add(_CellData(
          index: globalIndex,
          value: value,
          number: number,
          isRevealed: isRevealed,
        ));

        globalIndex++;
      }

      if (cells.isNotEmpty) words.add(cells);
      globalIndex++; // пропускаем пробел
    }

    return words;
  }
}

class _PhraseWord extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const _PhraseWord({required this.children, required this.spacing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

class _CellData {
  final int index;
  final String? value;
  final int? number;
  final bool isRevealed;

  const _CellData({
    required this.index,
    required this.value,
    required this.number,
    required this.isRevealed,
  });
}