import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api/player_service.dart';
import '../../../services/models/level.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/level_provider.dart'; // ← импортируем
import '../../menu_screen/menu_screen.dart';
import 'errors_display_widget.dart';

class CustomLevelAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int levelId;
  final int errorCount;
  final List<Level> allLevels;
  final Level currentLevel;

  const CustomLevelAppBar({
    super.key,
    required this.levelId,
    required this.errorCount,
    required this.allLevels,
    required this.currentLevel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF58AFFF), Color(0xFF3795F4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  await PlayerService.updateProgress(currentLevel.id, 0);

                  ref.invalidate(playerProvider);
                  ref.invalidate(levelsProvider);

                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(
                          levels: allLevels,
                          currentLevel: currentLevel,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.home, color: Colors.white),
                ),
              ),
              Expanded(
                child: Center(
                  child: ErrorsDisplayWidget(errorCount: errorCount),
                ),
              ),
              Text(
                'Level $levelId',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}