import 'package:flutter/material.dart';

class LevelCompleteDialog extends StatelessWidget {
  final String author;
  final VoidCallback onClose;

  const LevelCompleteDialog({
    super.key,
    required this.author,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Поздравляем!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://static.mk.ru/upload/entities/2022/09/28/19/articles/facebookPicture/20/d0/74/d6/3571bc56c4aa80038915faf4a02ed5d9.jpg',
              height: 150, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text("Автор: $author"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text("OK"),
        ),
      ],
    );
  }
}
