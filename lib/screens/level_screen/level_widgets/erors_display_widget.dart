import 'package:flutter/material.dart';

class ErorsDisplayWidget extends StatelessWidget {
  final int errorCount;

  const ErorsDisplayWidget({super.key, required this.errorCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ошибки',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              Icons.close_sharp,
              size: 28,
              color: index < errorCount ? Colors.red : Colors.grey,
            );
          }),
        ),
      ],
    );
  }
}
