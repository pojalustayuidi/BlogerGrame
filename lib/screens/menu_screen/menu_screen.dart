import 'package:blogergrame/screens/menu_screen/menu_widgets/topbar_ui_wdiget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../servises/models/level.dart';
import '../../servises/player_sevice.dart';
import '../level_screen/level_screen.dart';
import '../store_screen/shope_screen.dart';
import 'menu_widgets/buttons.dart';


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
  static const int maxLives = 5; // Исправлено с 1 на 5
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
    if (duration <= Duration.zero) return '00:00';
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
          parsedLastLifeUpdate = DateTime.tryParse(lastLifeRaw)?.toLocal();
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
        await _refreshLives(); // Вызываем сразу, чтобы синхронизировать время
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            error = true;
            lives = 0;
            coins = 0;
          });
        }
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
        final secondsToNextLife = response['secondsToNextLife'] as int?;
        final lastLifeRaw = response['lastLifeUpdate'] as String?;
        DateTime? parsedLastLifeUpdate;

        if (lastLifeRaw != null && lastLifeRaw.isNotEmpty) {
          parsedLastLifeUpdate = DateTime.tryParse(lastLifeRaw)?.toLocal();
        }

        if (mounted) {
          setState(() {
            lives = response['lives'] ?? lives;
            timeUntilNextLife = secondsToNextLife != null
                ? Duration(seconds: secondsToNextLife)
                : Duration.zero;
            lastLifeUpdate = parsedLastLifeUpdate ?? lastLifeUpdate;
            error = false;
          });
        }
      } else {
        if (mounted) setState(() => error = true);
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

    final now = DateTime.now().toLocal();
    final elapsedSeconds = now.difference(lastLifeUpdate!).inSeconds;
    final secondsLeft = restoreIntervalSeconds - (elapsedSeconds % restoreIntervalSeconds);

    if (secondsLeft <= 0 && !_isLoadingStatus) {
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
        content: const Text(
            'У вас закончились жизни. Дождитесь восстановления или купите жизни в магазине.'),
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

  // void _showErrorDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //         title: const Text('Ошибка сети'),
  //         content: const Text(
  //             'Не удалось подключиться к серверу. Проверьте интернет и попробуйте снова.'),
  //         actions: [
  //         TextButton(
  //         onPressed: () {
  //   Navigator.pop(context);
  //   _loadStatus();
  //   },
  //     child: const Text('Повторить'),
  //   ),
  //   ]);
  // }

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
            child: ElevatedButton(
              onPressed: _loadStatus,
              child: const Text('Попробовать снова'),
            ),
          )
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: TopBar(
                  lives: lives,
                  coins: coins,
                  maxLives: maxLives,
                  timeUntilNextLife: timeUntilNextLife,
                ),
              ),
              const SizedBox(height: 50),
              Buttons(
                lives: lives,
                currentLevel: widget.currentLevel,
                levels: widget.levels,
                onPressedContinue: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelScreen(
                        currentLevel: widget.currentLevel,
                        allLevels: widget.levels,
                      ),
                    ),
                  ).then((_) => _loadStatus());
                },
                showNoLivesDialog: _showNoLivesDialog,
                loadStatus: _loadStatus,
              ),
              const Spacer(flex: 1),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Версия 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//test_background_menu