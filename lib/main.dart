import 'package:blogergrame/screens/loading_screen/loading_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BlogerGrame',
      debugShowCheckedModeBanner: false,
      home:  LoadingScreen(),
    );
  }
}