
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api/level_servisec.dart';
import '../services/models/level.dart';

part 'level_provider.g.dart';

@riverpod
class Levels extends _$Levels {
  @override
  Future<List<Level>> build() async {
    print('Загрузка уровней...');

    try {
      final levels = await LevelService.fetchAllLevels();
      print('Загружено ${levels.length} уровней');
      return levels;
    } catch (e) {
      print('Ошибка: $e');
      throw Exception('Ошибка загрузки уровней: $e');
    }
  }

  Level? getLevelById(int id) {
    final levels = state.valueOrNull;
    if (levels == null) return null;

    try {
      return levels.firstWhere((level) => level.id == id);
    } catch (e) {
      return null;
    }
  }

  Level? getNextLevel(int currentId) {
    final levels = state.valueOrNull;
    if (levels == null) return null;

    final index = levels.indexWhere((level) => level.id == currentId);
    if (index != -1 && index < levels.length - 1) {
      return levels[index + 1];
    }
    return null;
  }
}