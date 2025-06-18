import 'package:flutter/material.dart';

class VirtualKeyboardWidget extends StatelessWidget {
  final void Function(String, void Function() onLetterAccepted) onLetterPressed;
  final List<int> correctIndices;
  final List<int> revealed;
  final Map<String, int> letterMap;
  final List<String?> userInput;
  final String fullPhrase;

  const VirtualKeyboardWidget({
    super.key,
    required this.onLetterPressed,
    required this.correctIndices,
    required this.revealed,
    required this.letterMap,
    required this.userInput,
    required this.fullPhrase,
  });

  bool isLetterCompleted(String letter) {
    final number = letterMap[letter];
    if (number == null) return false;

    final indices = fullPhrase
        .toLowerCase()
        .split('')
        .asMap()
        .entries
        .where((e) => letterMap[e.value] == number)
        .map((e) => e.key)
        .toList();

    return indices.every((index) =>
    revealed.contains(index) ||
        (userInput[index]?.toLowerCase() == fullPhrase[index].toLowerCase()));
  }

  bool isLetterUsed(String letter) {
    final number = letterMap[letter];
    if (number == null) return false;

    final indices = fullPhrase
        .toLowerCase()
        .split('')
        .asMap()
        .entries
        .where((e) => letterMap[e.value] == number)
        .map((e) => e.key)
        .toList();

    return indices.any((index) =>
    revealed.contains(index) ||
        (userInput[index]?.toLowerCase() == fullPhrase[index].toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    const letters = [
      'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж',
      'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О',
      'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц',
      'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'
    ];

    const lettersPerRow = 11;
    const spacing = 11.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final totalSpacing = (lettersPerRow - 1) * spacing + 16; // padding
    final buttonWidth = (screenWidth - totalSpacing) / lettersPerRow;
    final buttonHeight = buttonWidth * 2.35; // можно подправить под вкус

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black12,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: letters.map((letter) {
          final lower = letter.toLowerCase();
          final completed = isLetterCompleted(lower);
          final used = isLetterUsed(lower);

          Color bgColor;
          Color fgColor;

          if (completed) {
            bgColor = Colors.grey[400]!;
            fgColor = Colors.grey[700]!;
          } else if (used) {
            bgColor = Colors.green[300]!;
            fgColor = Colors.black;
          } else {
            bgColor = Colors.white;
            fgColor = Colors.black;
          }

          return SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: completed ? null : () => onLetterPressed(letter, () {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(
                letter,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
