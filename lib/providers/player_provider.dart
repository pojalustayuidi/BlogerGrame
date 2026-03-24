import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api/player_service.dart';

part 'player_provider.g.dart';

class PlayerData {
  final String id;
  final int coins;
  final int lives;
  final int hints;
  final int currentLevel;
  final DateTime? lastLifeUpdate;

  PlayerData({
    required this.id,
    required this.coins,
    required this.lives,
    required this.hints,
    required this.currentLevel,
    required this.lastLifeUpdate,
  });

  PlayerData copyWith({
    String? id,
    int? coins,
    int? lives,
    int? hints,
    int? currentLevel,
    DateTime? lastLifeUpdate,
  }) {
    return PlayerData(
      id: id ?? this.id,
      coins: coins ?? this.coins,
      lives: lives ?? this.lives,
      hints: hints ?? this.hints,
      currentLevel: currentLevel ?? this.currentLevel,
      lastLifeUpdate: lastLifeUpdate ?? this.lastLifeUpdate,
    );
  }
}

@riverpod
class Player extends _$Player {
  @override
  Future<PlayerData> build() async {
    final id = await PlayerService.registerPlayer();
    if (id == null) {
      throw Exception('Не удалось зарегистрировать игрока');
    }

    final status = await PlayerService.getStatus();
    final currentLevel = await PlayerService.getCurrentLevel();
    final stats = await PlayerService.getPlayerStats();

    DateTime? lastLifeUpdate;
    if (status?['last_life_update'] != null) {
      lastLifeUpdate = DateTime.tryParse(status!['last_life_update']);
    }

    return PlayerData(
      id: id,
      coins: status?['coins'] ?? 0,
      lives: status?['lives'] ?? 5,
      hints: stats?['hints'] ?? 0,
      currentLevel: currentLevel ?? 1,
      lastLifeUpdate: lastLifeUpdate,
    );
  }

  // 💰 МЕТОД для обновления монет
  void updateCoins(int newCoins) {
    final current = state.valueOrNull;
    if (current != null) {
      print('💰 Обновляем монеты: ${current.coins} → $newCoins');
      state = AsyncValue.data(current.copyWith(coins: newCoins));

      // Отправляем на сервер в фоне
      PlayerService.updateStatus(coins: newCoins);
    }
  }

  Future<bool> decrementLives() async {
    final current = state.valueOrNull;
    if (current == null) {
      print('❌ Не удалось отнять жизнь: данные игрока не загружены');
      return false;
    }

    if (current.lives <= 0) {
      print('❌ Не удалось отнять жизнь: жизней нет');
      return false;
    }

    print('🎮 Отнимаем жизнь: ${current.lives} → ${current.lives - 1}');

    final updated = current.copyWith(lives: current.lives - 1);
    state = AsyncValue.data(updated);

    try {
      final success = await PlayerService.decrementLives();

      if (!success) {
        print('⚠️ Сервер не принял изменение, откатываем...');
        state = AsyncValue.data(current);
        return false;
      }

      print('✅ Жизнь успешно отнята');
      return true;
    } catch (e) {
      print('❌ Ошибка сервера: $e');
      state = AsyncValue.data(current);
      return false;
    }
  }

  void updateLives(int newLives) {
    final current = state.valueOrNull;
    if (current != null) {
      print('🔄 Обновляем жизни: ${current.lives} → $newLives');
      state = AsyncValue.data(current.copyWith(lives: newLives));
    }
  }

  void updateHints(int newHints) {
    final current = state.valueOrNull;
    if (current != null) {
      print('💡 Обновляем подсказки: ${current.hints} → $newHints');
      state = AsyncValue.data(current.copyWith(hints: newHints));
    }
  }

  Future<bool> useHint() async {
    final current = state.valueOrNull;
    if (current == null || current.hints <= 0) return false;

    final updated = current.copyWith(hints: current.hints - 1);
    state = AsyncValue.data(updated);

    return true;
  }

  void updateLastLifeUpdate(DateTime newTime) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(lastLifeUpdate: newTime));
    }
  }
}