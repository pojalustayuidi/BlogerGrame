import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dev/backend_check_screen.dart';

/// Development-only entrypoint. Production lib/main.dart is untouched.
void main() => runApp(const ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BlogerGrame · Backend Test',
        home: BackendCheckScreen(),
      ),
    ));
