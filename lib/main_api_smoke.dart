import 'package:flutter/material.dart';
import 'dev/backend_check_screen.dart';

/// Temporary development entry point. Normal lib/main.dart is unchanged.
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BlogerGrame · Backend Test',
    home: BackendCheckScreen(),
  ));
}
