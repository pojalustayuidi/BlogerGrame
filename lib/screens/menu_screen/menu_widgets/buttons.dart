import 'package:flutter/material.dart';
import '../../../servises/models/level.dart';
import '../../store_screen/shope_screen.dart';

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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: ElevatedButton(
            onPressed: lives > 0 ? onPressedContinue : showNoLivesDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor:
                  lives > 0 ? const Color(0xFF32C671) : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: lives > 0
                  ? const Color(0xFF229F57).withOpacity(0.83)
                  : Colors.grey.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'ПРОДОЛЖИТЬ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Franklin',
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Уровень ${currentLevel.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: ElevatedButton.icon(
            label: const Text(
              'МАГАЗИН',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontFamily: 'Franklin',
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
              loadStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFDF0DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: screenWidth * 0.75,
          height: screenHeight * 0.1,
          child: ElevatedButton.icon(
            label: const Text(
              'НАСТРОЙКИ',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                  fontFamily: 'Franklin',
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
              loadStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFDF0DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
