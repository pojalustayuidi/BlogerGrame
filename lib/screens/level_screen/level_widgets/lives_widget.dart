import 'package:flutter/material.dart';

class LivesDisplayWidget extends StatelessWidget {
  final int lives;

  const LivesDisplayWidget({super.key, required this.lives});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ошибки',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              Icons.favorite,
              size: 16,
              color: index < lives ? Colors.red : Colors.grey,
            );
          }),
        ),
      ],
    );
  }
}
