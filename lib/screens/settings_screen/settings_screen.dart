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
          ref.read(playerProvider.notifier).updateCoins(player.coins + rewardCoins);
        }

        if (rewardHints > 0) {
          ref.read(playerProvider.notifier).updateHints(player.hints + rewardHints);
        }

        if (rewardLives > 0) {
          final newLives = (player.lives + rewardLives).clamp(0, 5);
          ref.read(playerProvider.notifier).updateLives(newLives);
        }
      }

      final rewards = <String>[
        if (rewardCoins > 0) '+$rewardCoins монет',
        if (rewardHints > 0) '+$rewardHints подсказок',
        if (rewardLives > 0) '❤+$rewardLives жизней',
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
          title: Row(
            children: const [
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog() {
    final player = ref.read(playerProvider).valueOrNull;
    if (player == null) return;

    final solvedPuzzles = player.currentLevel - 1;
    const totalLevels = 8;
    final progress = totalLevels > 0 ? solvedPuzzles / totalLevels : 0.0;
    final percent = (progress * 100).clamp(0, 100);

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
            onRefresh: () async {
              ref.invalidate(settingsProvider);
              ref.invalidate(playerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                playerAsync.when(
                  data: (player) => _ResourcesCard(player: player),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                const _SectionTitle('Аудио'),
                const SizedBox(height: 10),

                _SettingsCard(
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.volume_up_rounded,
                      iconBg: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      title: 'Звуки',
                      subtitle: 'Включить или выключить игровые звуки',
                      value: settings.soundEnabled,
                      onChanged: (_) {
                        ref.read(settingsProvider.notifier).toggleSound();
                      },
                    ),
                    const _InnerDivider(),
                    _SettingsSwitchTile(
                      icon: Icons.music_note_rounded,
                      iconBg: Colors.green.shade50,
                      iconColor: Colors.green,
                      title: 'Музыка',
                      subtitle: 'Фоновая музыка в игре',
                      value: settings.musicEnabled,
                      onChanged: (_) {
                        ref.read(settingsProvider.notifier).toggleMusic();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const _SectionTitle('Бонусы и прогресс'),
                const SizedBox(height: 10),

                _SettingsCard(
                  children: [
                    _ActionTile(
                      icon: Icons.card_giftcard_rounded,
                      iconBg: Colors.purple.shade50,
                      iconColor: Colors.purple,
                      title: 'Промокод',
                      subtitle: 'Введите промокод и получите награды',
                      trailing: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _isLoading ? null : _showPromoCodeDialog,
                    ),
                    const _InnerDivider(),
                    _ActionTile(
                      icon: Icons.bar_chart_rounded,
                      iconBg: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      title: 'Статистика',
                      subtitle: 'Посмотреть прогресс прохождения',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showStatsDialog,
                    ),
                  ],
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

class _ResourcesCard extends StatelessWidget {
  final dynamic player;

  const _ResourcesCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: const Color(0xFF5B8DEF).withOpacity(0.28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваши ресурсы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ResourceStat(
                  icon: Image.asset('assets/coins.png', width: 26, height: 26),
                  value: player.coins,
                  label: 'Монет',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResourceStat(
                  icon: Image.asset('assets/icon_hint.png', width: 26, height: 26),
                  value: player.hints,
                  label: 'Подсказок',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResourceStat(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 26),
                  value: player.lives,
                  label: 'Жизней',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceStat extends StatelessWidget {
  final Widget icon;
  final int value;
  final String label;

  const _ResourceStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF5B8DEF),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: trailing,
    );
  }
}

class _InnerDivider extends StatelessWidget {
  const _InnerDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}