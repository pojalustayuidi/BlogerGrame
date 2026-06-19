import 'package:blogergrame/screens/settings_screen/settings_widget/settings_audio_section.dart';
import 'package:blogergrame/screens/settings_screen/settings_widget/settings_bonus_section.dart' show SettingsBonusSection;
import 'package:blogergrame/screens/settings_screen/settings_widget/settings_resources_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/api/promo_service.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _checkPromoCode(String code) async {
    if (code.isEmpty) {
      _showSnackBar(
        'Введите промокод',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    final playerId = ref.read(playerProvider).valueOrNull?.id ?? '';
    if (playerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar(
        'Ошибка: playerId не найден',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final result = await PromoService.redeemPromoCode(
        playerId: playerId,
        promoCode: code,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result == null) {
        _showSnackBar(
          'Ошибка соединения с сервером',
          backgroundColor: Colors.red,
        );
        return;
      }

      if (result['success'] == true) {
        final rewardCoins = result['reward_coins'] is int
            ? result['reward_coins'] as int
            : int.tryParse(result['reward_coins'].toString()) ?? 0;

        final rewardHints = result['reward_hints'] is int
            ? result['reward_hints'] as int
            : int.tryParse(result['reward_hints'].toString()) ?? 0;

        final rewardLives = result['reward_lives'] is int
            ? result['reward_lives'] as int
            : int.tryParse(result['reward_lives'].toString()) ?? 0;

        final player = ref.read(playerProvider).valueOrNull;
        if (player != null) {
          if (rewardCoins > 0) {
            ref
                .read(playerProvider.notifier)
                .updateCoins(player.coins + rewardCoins);
          }

          if (rewardHints > 0) {
            ref
                .read(playerProvider.notifier)
                .updateHints(player.hints + rewardHints);
          }

          if (rewardLives > 0) {
            final newLives = (player.lives + rewardLives).clamp(0, 5);
            ref.read(playerProvider.notifier).updateLives(newLives);
          }
        }

        final rewards = <String>[
          if (rewardCoins > 0) '+$rewardCoins монет',
          if (rewardHints > 0) '+$rewardHints подсказок',
          if (rewardLives > 0) '❤ +$rewardLives жизней',
        ].join('\n');

        _showSnackBar(
          'Промокод активирован!\n$rewards',
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        );
      } else {
        final errorMessage = result['error'] ?? 'Неизвестная ошибка';
        _showSnackBar(
          errorMessage,
          backgroundColor: Colors.red,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        'Не удалось активировать промокод',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSnackBar(
      String message, {
        Color backgroundColor = Colors.black87,
        Duration duration = const Duration(seconds: 2),
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPromoCodeDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF3E8FF),
                child: Icon(Icons.card_giftcard, color: Colors.purple),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Введите промокод',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Например: BLOGERGRAMETG2026',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Доступные промокоды:\n'
                        '• BLOGERGRAMETG2026 — 500 монет\n'
                        '• BONUSGAME300 — 300 монет\n'
                        '• HINTSFREE2026 — 3 подсказки\n'
                        '• LIVES2026 — 5 жизней',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                _checkPromoCode(controller.text.trim().toUpperCase());
              },
              icon: const Icon(Icons.check),
              label: const Text('Применить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _showStatsDialog() {
    final player = ref.read(playerProvider).valueOrNull;
    if (player == null) return;

    const totalLevels = 8;
    final solvedPuzzles = (player.currentLevel - 1).clamp(0, totalLevels);
    final progress =
    totalLevels > 0 ? (solvedPuzzles / totalLevels).clamp(0.0, 1.0) : 0.0;
    final percent = progress * 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Статистика',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 38,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Решено уровней: $solvedPuzzles из $totalLevels',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
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
  }

  Future<void> _onRefresh() async {
    ref.invalidate(settingsProvider);
    ref.invalidate(playerProvider);

    await Future.wait([
      ref.read(settingsProvider.future),
      ref.read(playerProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF5B8DEF),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                playerAsync.when(
                  data: (player) => SettingsResourcesCard(player: player),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                SettingsAudioSection(
                  settings: settings,
                  onSoundChanged: (_) {
                    ref.read(settingsProvider.notifier).toggleSound();
                  },
                  onMusicChanged: (_) {
                    ref.read(settingsProvider.notifier).toggleMusic();
                  },
                ),
                const SizedBox(height: 20),
                SettingsBonusSection(
                  isLoading: _isLoading,
                  onPromoTap: _isLoading ? null : _showPromoCodeDialog,
                  onStatsTap: _showStatsDialog,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(0.06),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ошибка: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(settingsProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8DEF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}