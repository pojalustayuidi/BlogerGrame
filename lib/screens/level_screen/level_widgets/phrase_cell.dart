import 'package:flutter/material.dart';

class PhraseCell extends StatelessWidget {
  final int index;
  final String? value;
  final int? number;
  final bool isRevealed;
  final bool isSelected;
  final bool isIncorrect;
  final bool isCorrect;
  final bool isCompleted;
  final VoidCallback onTap;

  const PhraseCell({
    super.key,
    required this.index,
    required this.value,
    required this.number,
    required this.isRevealed,
    required this.isSelected,
    required this.isIncorrect,
    required this.isCorrect,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 Даже если isRevealed — цифра пропадает, если isCompleted
    final shouldShowNumber = number != null && !isCompleted;

    return GestureDetector(
      onTap: isRevealed || isCorrect ? null : onTap,
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
                  : isIncorrect
                  ? Colors.red.withOpacity(0.8)
                  : isSelected
                  ? Colors.green.withOpacity(0.8)
                  : isCompleted
                  ? Colors.grey[200]
                  : Colors.white,
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value?.toUpperCase() ?? '_',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shouldShowNumber ? number.toString() : '',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
