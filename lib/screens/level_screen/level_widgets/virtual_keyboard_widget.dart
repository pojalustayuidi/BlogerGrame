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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = screenHeight * 0.25;

    const row1 = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й'];
    const row2 = ['К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф'];
    const row3 = ['Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'];

    Widget buildRow(List<String> rowLetters) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowLetters.map((letter) {
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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: 32,
                height: 48,
                child: ElevatedButton(
                  onPressed: completed ? null : () => onLetterPressed(letter, () {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    padding: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      height: keyboardHeight,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          buildRow(row1),
          const SizedBox(height: 6),
          buildRow(row2),
          const SizedBox(height: 6),
          buildRow(row3),
        ],
      ),
    );
  }
}
