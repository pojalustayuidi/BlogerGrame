import 'package:flutter/material.dart';
import '../../../services/models/level.dart';
import '../../store_screen/shope_screen.dart';
import '../../settings_screen/settings_screen.dart';

class Buttons extends StatelessWidget {
  final int lives;
  final Level currentLevel;
  final List<Level> levels;
  final VoidCallback onPressedContinue;
  final VoidCallback showNoLivesDialog;
  final VoidCallback loadStatus;

  const Buttons({
    super.key,
    required this.lives,
    required this.currentLevel,
    required this.levels,
    required this.onPressedContinue,
    required this.showNoLivesDialog,
    required this.loadStatus,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🟢 Кнопка ПРОДОЛЖИТЬ (НОВЫЙ ДИЗАЙН)
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                if (lives > 0)
                  BoxShadow(
                    color: const Color(0xFF2BFF88).withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: lives > 0 ? onPressedContinue : showNoLivesDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: EdgeInsets.zero,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                    if (lives <= 0) return Colors.grey.shade400;
                    return Colors.transparent;
                  },
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: lives > 0
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2BFF88),
                      Color(0xFF19C37D),
                    ],
                  )
                      : null,
                  color: lives <= 0 ? Colors.grey.shade400 : null,
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ПРОДОЛЖИТЬ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Уровень ${currentLevel.id}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 🟡 Кнопка МАГАЗИН (старый дизайн)
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
              loadStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDF0DC),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            child: const Text(
              'МАГАЗИН',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 🔵 Кнопка НАСТРОЙКИ (старый дизайн)
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              loadStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDF0DC),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            child: const Text(
              'НАСТРОЙКИ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}