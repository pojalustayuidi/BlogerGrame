import 'package:blogergrame/screens/level_screen/level_screen.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LevelScreen()));
        },
        child: const Text(
          'Играть',
          style: TextStyle(fontSize: 20),
        ));
  }
}
