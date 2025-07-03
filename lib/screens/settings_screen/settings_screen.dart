import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../servises/player_sevice.dart';
import '../../servises/promo_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  int _solvedPuzzles = 0;
  int _totalLevels = 8;
  int _coins = 0;
  int _hints = 0;
  int _lives = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchPlayerStats();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('musicEnabled', _musicEnabled);
  }

  Future<void> _fetchPlayerStats() async {
    final stats = await PlayerService.getPlayerStats();
    if (stats != null) {
      setState(() {
        _solvedPuzzles = stats['completedLevels'] ?? 0;
        _totalLevels = stats['totalLevels'] ?? 8;
        _coins = stats['coins'] ?? 0;
        _hints = stats['hints'] ?? 0;
        _lives = stats['lives'] ?? 0;
      });
    }
  }

  Future<void> _checkPromoCode(String code) async {
    setState(() {
      _isLoading = true;
    });

    final playerId = await PlayerService.getCurrentPlayerId();
    if (playerId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: playerId не найден')),
      );
      return;
    }

    final result = await PromoService.redeemPromoCode(
      playerId: playerId,
      promoCode: code,
    );

    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка соединения с сервером')),
      );
      return;
    }

    if (result['success'] == true) {
      await _fetchPlayerStats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Промокод активирован! Получено: ${result['reward_coins'] ?? 0} монет, '
            '${result['reward_hints'] ?? 0} подсказок, ${result['reward_lives'] ?? 0} жизней',
          ),
        ),
      );
    } else {
      final errorMessage = result['error'] ?? 'Неизвестная ошибка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _showPromoCodeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введите промокод'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Промокод'),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    _checkPromoCode(controller.text.trim());
                  },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/coins.png',
              ),
              Text('$_coins Монет'),
              SizedBox(
                width: 33,
              ),
              Image.asset('assets/icon_hint.png', scale: 15),
              Text('$_hints Подсказок'),
              SizedBox(
                width: 33,
              ),
              Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              Text('$_lives')
            ],
          ),Divider(),
          SwitchListTile(
            title: const Text('🔊 Звуки'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
                _saveSettings();
              });
            },
          ),Divider(),
          SwitchListTile(
            title: const Text('🎵 Музыка'),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() {
                _musicEnabled = value;
                _saveSettings();
              });
            },
          ),Divider(),
          ListTile(
            title: const Text('🎁 Промокод'),
            subtitle: const Text('Введите промокод для наград'),
            trailing: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.arrow_forward),
            onTap: _isLoading ? null : _showPromoCodeDialog,
          ),Divider(),
          ListTile(
            title: const Text('📊 Статистика'),
            trailing: const Icon(Icons.bar_chart),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Статистика игрока'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Решенных уровней: $_solvedPuzzles из $_totalLevels'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalLevels > 0
                            ? _solvedPuzzles / _totalLevels
                            : 0,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
