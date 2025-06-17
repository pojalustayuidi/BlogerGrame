import 'package:flutter/material.dart';

class VirtualKeyboardWidget extends StatefulWidget {
  final void Function(String) onLetterPressed;

  const VirtualKeyboardWidget({super.key, required this.onLetterPressed});

  @override
  State<VirtualKeyboardWidget> createState() => _VirtualKeyboardWidgetState();
}

class _VirtualKeyboardWidgetState extends State<VirtualKeyboardWidget> {
  static const letters = [
    'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж',
    'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О',
    'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц',
    'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'
  ];

  final Set<String> usedLetters = {};

  void handlePress(String letter) {
    if (usedLetters.contains(letter)) {
      return;
    }
    setState(() {
      usedLetters.add(letter);
    });
    widget.onLetterPressed(letter.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black12,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: letters.map((letter) {
          final isUsed = usedLetters.contains(letter);
          return ElevatedButton(
            onPressed: isUsed ? null : () => handlePress(letter),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUsed ? Colors.grey[400] : Colors.white,
              foregroundColor: isUsed ? Colors.grey[600] : Colors.black,
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              letter,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}