import 'package:flutter/material.dart';

/// Colors are taken from Prufani Asset Kit v1.1 (docs/design_tokens.json).
abstract final class PrufaniColors {
  static const primary = Color(0xFF7B5CFF);
  static const primaryDark = Color(0xFF5536BA);
  static const purpleLight = Color(0xFFA88AFF);
  static const yellow = Color(0xFFFFE066);
  static const gold = Color(0xFFFFB928);
  static const pink = Color(0xFFFF7FA3);
  static const cream = Color(0xFFFFF9F3);
  static const lavender = Color(0xFFF8F0FF);
  static const panel = Color(0xFFE9E3FF);
  static const ink = Color(0xFF27213F);
  static const muted = Color(0xFF8C84A0);
  static const streamer = Color(0xFFFFE7DA);
  static const blogger = Color(0xFFEEE6FF);
  static const tiktoker = Color(0xFFDDF7F1);
}

/// Only paths from the user's supplied Asset Kit. No screenshots are embedded
/// in the actual UI; cards, labels and progress bars are real Flutter widgets.
abstract final class PrufaniAssets {
  static const logo = 'assets/prufani/brand/prufani_logo.png';
  static const loadingBackground = 'assets/prufani/loading/loading_background.jpg';
  static const readingMascot = 'assets/prufani/loading/mascot_reading.png';
  static const loadingSparkles = 'assets/prufani/loading/loading_sparkles.svg';
  static const background = 'assets/prufani/backgrounds/cream.png';
  static const coin = 'assets/prufani/icons/resources/coin.png';
  static const coins = 'assets/prufani/icons/resources/coins_stack.png';
  static const heart = 'assets/prufani/icons/resources/heart_full.png';
  static const bulb = 'assets/prufani/icons/resources/bulb.png';
  static const crown = 'assets/prufani/icons/resources/crown.png';
  static const gamepad = 'assets/prufani/icons/features/gamepad.png';
  static const clapper = 'assets/prufani/icons/features/clapper.png';
  static const daily = 'assets/prufani/icons/features/daily_calendar.png';
  static const case404 = 'assets/prufani/icons/features/case_404.png';
  static const home = 'assets/prufani/icons/navigation/home.svg';
  static const categories = 'assets/prufani/icons/navigation/categories.svg';
  static const shop = 'assets/prufani/icons/navigation/shop.svg';
  static const profile = 'assets/prufani/icons/navigation/profile.svg';
  static const settings = 'assets/prufani/icons/navigation/settings.svg';
  static const streamers = 'assets/prufani/icons/categories/streamers.png';
  static const bloggers = 'assets/prufani/icons/categories/bloggers.png';
  static const tiktokers = 'assets/prufani/icons/categories/tiktokers.png';
}

ThemeData buildPrufaniTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PrufaniColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PrufaniColors.primary,
        surface: PrufaniColors.cream,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: PrufaniColors.ink),
        bodyLarge: TextStyle(color: PrufaniColors.ink),
        titleLarge: TextStyle(color: PrufaniColors.ink),
      ),
    );
