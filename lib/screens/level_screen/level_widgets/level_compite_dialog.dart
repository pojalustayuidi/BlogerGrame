import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/models/level.dart';
import '../../menu_screen/menu_screen.dart';
import '../level_screen.dart';

class LevelCompletedDialog extends ConsumerWidget {
  final int levelNumber;
  final Level currentLevel;
  final List<Level> allLevels;
  final String? formattedTime;
  final int rewards;
  final int coinsAdded;
  final int newcoins;

  const LevelCompletedDialog({
    super.key,
    required this.levelNumber,
    required this.currentLevel,
    required this.allLevels,
    this.formattedTime,
    required this.rewards,
    required this.coinsAdded,
    required this.newcoins,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextIndex = allLevels.indexOf(currentLevel) + 1;
    final hasNextLevel = nextIndex < allLevels.length;
    final nextLevel = hasNextLevel ? allLevels[nextIndex] : currentLevel;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                blurRadius: 28,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompletedHeader(levelNumber: levelNumber),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuoteCard(
                        quote: currentLevel.quote,
                        author: currentLevel.author,
                      ),
                      if (formattedTime != null) ...[
                        const SizedBox(height: 12),
                        _InfoMiniCard(
                          icon: Icons.schedule_rounded,
                          title: 'Время прохождения',
                          value: formattedTime!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _RewardCard(
                        coinsAdded: coinsAdded,
                        newcoins: newcoins,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Меню',
                              icon: Icons.home_rounded,
                              isPrimary: false,
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => MenuScreen(
                                      levels: allLevels,
                                      currentLevel: nextLevel,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: hasNextLevel ? 'Далее' : 'Готово',
                              icon: hasNextLevel
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                              isPrimary: true,
                              onTap: () {
                                if (hasNextLevel) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => LevelScreen(
                                        currentLevel: nextLevel,
                                        allLevels: allLevels,
                                      ),
                                    ),
                                  );
                                } else {
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  final int levelNumber;

  const _CompletedHeader({
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Уровень пройден!',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Уровень $levelNumber завершён успешно',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final String quote;
  final String author;

  const _QuoteCard({
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFF5B8DEF),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '«$quote»',
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.45,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— $author',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5B8DEF),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final int coinsAdded;
  final int newcoins;

  const _RewardCard({
    required this.coinsAdded,
    required this.newcoins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Награда',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RewardMiniTile(
                  icon: Image.asset(
                    'assets/coins.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  label: 'Получено',
                  value: '+$coinsAdded',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RewardMiniTile(
                  icon: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF5B8DEF),
                    size: 24,
                  ),
                  label: 'Теперь',
                  value: '$newcoins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardMiniTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const _RewardMiniTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
          isPrimary ? const Color(0xFF5B8DEF) : Colors.white,
          foregroundColor:
          isPrimary ? Colors.white : const Color(0xFF374151),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}