import 'package:flutter/material.dart';

import '../../../servises/models/level.dart';
class PhraseDisplayWidget extends StatelessWidget {
  final Level level;
  final List<String?> userInput;
  final int? selectedIndex;
  final void Function(int index) onSelect;

  const PhraseDisplayWidget({
    super.key,
    required this.level,
    required this.userInput,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(level.quote.length, (i) {
        final char = level.quote[i];
        final isRevealed = level.revealed.contains(i);
        final displayedChar = isRevealed ? char : (userInput[i] ?? '_');
        final letter = char.toLowerCase();
        final number = level.letterMap[letter];
        final isSelected = selectedIndex == i;

        return GestureDetector(
          onTap: () {
            if (!isRevealed) onSelect(i);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isRevealed
                      ? Colors.transparent
                      : isSelected
                      ? Colors.green.withOpacity(0.3)
                      : Colors.black12,
                  border: Border.all(color: Colors.black26),
                ),
                child: Text(
                  displayedChar,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                number != null ? number.toString() : '',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      }),
    );
  }
}
