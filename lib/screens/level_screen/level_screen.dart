import 'package:blogergrame/screens/level_screen/level_widgets/button.dart';
import 'package:flutter/material.dart';
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(children: [Button()]),);
  }
}
