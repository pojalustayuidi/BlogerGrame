import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/prufani_theme.dart';
import 'screens/loading_screen/loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PrufaniApp()));
}

class PrufaniApp extends StatelessWidget {
  const PrufaniApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ПРУФАНИ!',
        debugShowCheckedModeBanner: false,
        theme: buildPrufaniTheme(),
        // Keep a fixed visual style independent of device light/dark theme.
        darkTheme: buildPrufaniTheme(),
        themeMode: ThemeMode.light,
        home: const PrufaniStartupGate(),
      );
}
