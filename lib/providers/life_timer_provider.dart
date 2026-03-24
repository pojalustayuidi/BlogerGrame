import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'player_provider.dart';
import '../services/api/player_service.dart';

part 'life_timer_provider.g.dart';

// Этот провайдер будет хранить время до следующей жизни
@riverpod
class LifeTimer extends _$LifeTimer {
  Timer? _timer;

  @override
  Duration build() {
    // Очищаем таймер при уничтожении провайдера
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // Слушаем изменения игрока
    final player = ref.watch(playerProvider).valueOrNull;

    // Если игрока нет или жизни полные - таймер не нужен
    if (player == null || player.lives >= 5) {
      _timer?.cancel();
      _timer = null;
      return Duration.zero;
    }

    // Запускаем тиканье каждую секунду
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      // Перезапускаем провайдер чтобы пересчитать время
      ref.invalidateSelf();
    });

    // Вычисляем сколько осталось до следующей жизни
    return _calculateTimeToNextLife(player);
  }

  // Вычисляем время до следующей жизни
  Duration _calculateTimeToNextLife(PlayerData player) {
    if (player.lastLifeUpdate == null) return Duration.zero;

    const restoreInterval = Duration(minutes: 15);
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(player.lastLifeUpdate!);

    // Если прошло больше 15 минут - пора обновить жизни
    if (timeSinceLastUpdate >= restoreInterval) {
      _refreshLivesFromServer();
      return Duration.zero;
    }

    // Сколько осталось до следующих 15 минут
    final remaining = restoreInterval - timeSinceLastUpdate;
    return remaining;
  }

  // Запрашиваем обновление жизней с сервера
  Future<void> _refreshLivesFromServer() async {
    final player = ref.read(playerProvider).valueOrNull;
    if (player == null) return;

    print('🔄 Запрашиваем восстановление жизней...');

    final result = await PlayerService.refreshLives(player.id);
    if (result != null) {
      // Обновляем данные игрока
      ref.read(playerProvider.notifier).updateLives(result['lives']);

      if (result['lastLifeUpdate'] != null) {
        final newTime = DateTime.tryParse(result['lastLifeUpdate']);
        if (newTime != null) {
          ref.read(playerProvider.notifier).updateLastLifeUpdate(newTime);
        }
      }

      print('✅ Жизни обновлены: ${result['lives']}');
    }
  }

  // Принудительно проверить жизни (можно вызвать извне)
  Future<void> checkLivesNow() async {
    await _refreshLivesFromServer();
    ref.invalidateSelf();
  }
}