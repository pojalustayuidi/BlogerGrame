import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../servises/models/level.dart';
import '../../servises/player_sevice.dart';
import '../level_screen/level_screen.dart';
import '../store_screen/shope_screen.dart';

class MenuScreen extends StatefulWidget {
  final List<Level> levels;
  final Level currentLevel;

  const MenuScreen({
    super.key,
    required this.levels,
    required this.currentLevel,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const int maxLives = 5;
  static const int restoreIntervalSeconds = 15 * 60; // 15 минут

  int lives = 0;
  int coins = 0;
  bool loading = true;
  bool error = false;
  DateTime? lastLifeUpdate;
  Timer? _timer;
  Duration timeUntilNextLife = Duration.zero;
  bool _isLoadingStatus = false;

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _loadStatus().then((_) {
      if (mounted) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateTimeUntilNextLife();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    if (_isLoadingStatus) return;
    _isLoadingStatus = true;

    try {
      final status = await PlayerService.getStatus();
      if (status != null) {
        final lastLifeRaw = status['last_life_update'];
        DateTime? parsedLastLifeUpdate;

        if (lastLifeRaw is String && lastLifeRaw.isNotEmpty) {
          parsedLastLifeUpdate = DateTime.tryParse(lastLifeRaw)?.toUtc();
        } else {
          print('Предупреждение: last_life_update отсутствует или некорректно');
        }

        if (mounted) {
          setState(() {
            lives = status['lives'] ?? 0;
            coins = status['coins'] ?? 0;
            lastLifeUpdate = parsedLastLifeUpdate;
            loading = false;
            error = false;
          });
        }
        print('Статус загружен: lives=$lives, coins=$coins, lastLifeUpdate=$lastLifeUpdate');
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            error = true;
            lives = 0;
            coins = 0;
          });
        }
        print('Статус не загружен: сервер недоступен или нет playerId');
      }
    } catch (e) {
      print('Ошибка загрузки статуса: $e');
      if (mounted) {
        setState(() {
          loading = false;
          error = true;
        });
      }
    } finally {
      _isLoadingStatus = false;
    }
  }

  Future<void> _refreshLives() async {
    if (_isLoadingStatus) return;
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('playerId');
    if (playerId == null) {
      print('Нет playerId для восстановления жизней');
      if (mounted) setState(() => error = true);
      return;
    }

    try {
      final response = await PlayerService.refreshLives(playerId);
      if (response != null) {
        if (response.containsKey('minutesToNextLife')) {
          final minutesToNextLife = response['minutesToNextLife'] as int;
          if (mounted) {
            setState(() {
              timeUntilNextLife = Duration(minutes: minutesToNextLife);
              lives = response['lives'] ?? lives;
              error = false;
            });
          }
          print('Осталось минут до восстановления: $minutesToNextLife');
        } else {
          print('Жизни успешно восстановлены на сервере');
          await _loadStatus();
        }
      } else {
        if (mounted) setState(() => error = true);
        print('Ошибка: /refresh-lives вернул null');
      }
    } catch (e) {
      print('Ошибка при восстановлении жизней: $e');
      if (mounted) setState(() => error = true);
    }
  }

  void _updateTimeUntilNextLife() {
    if (lastLifeUpdate == null || lives >= maxLives) {
      if (timeUntilNextLife != Duration.zero && mounted) {
        setState(() => timeUntilNextLife = Duration.zero);
      }
      return;
    }

    final now = DateTime.now().toUtc();
    final elapsedSeconds = now.difference(lastLifeUpdate!).inSeconds;
    final secondsLeft = restoreIntervalSeconds - elapsedSeconds;

    if (secondsLeft <= 0 && !_isLoadingStatus) {
      print('Время для восстановления жизни истекло, вызываем refreshLives');
      _refreshLives();
    } else if (secondsLeft > 0 && mounted) {
      final newDuration = Duration(seconds: secondsLeft);
      if (newDuration != timeUntilNextLife) {
        setState(() => timeUntilNextLife = newDuration);
      }
    }
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Жизни закончились'),
        content: const Text('У вас закончились жизни. Дождитесь восстановления или купите жизни в магазине.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              ).then((_) => _loadStatus());
            },
            child: const Text('В магазин'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка сети'),
        content: const Text('Не удалось подключиться к серверу. Проверьте интернет и попробуйте снова.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadStatus();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : error
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ошибка загрузки данных',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadStatus,
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          maxLives,
                              (index) => Icon(
                            Icons.favorite,
                            color: index < lives ? Colors.red : Colors.grey.shade400,
                          ),
                        ),
                        if (lives < maxLives && timeUntilNextLife > Duration.zero)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${formatDuration(timeUntilNextLife)}',
                              style: const TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(coins.toString(), style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Добро пожаловать!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Продолжить с ${widget.currentLevel.id} уровня'),
                  onPressed: lives > 0
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelScreen(
                          currentLevel: widget.currentLevel,
                          allLevels: widget.levels,
                        ),
                      ),
                    ).then((_) => _loadStatus());
                  }
                      : _showNoLivesDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: lives > 0 ? null : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Магазин'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                    await _loadStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Настройки'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Версия 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}