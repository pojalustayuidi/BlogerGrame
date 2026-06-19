import 'package:flutter/material.dart';

class MenuTopBar extends StatelessWidget {
  final int lives;
  final int coins;
  final int maxLives;
  final Duration timeUntilNextLife;

  const MenuTopBar({
    super.key,
    required this.lives,
    required this.coins,
    required this.maxLives,
    required this.timeUntilNextLife,
  });

  String formatDuration(Duration duration) {
    if (duration <= Duration.zero) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = lives < maxLives && timeUntilNextLife > Duration.zero;

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Expanded(
            child: _TopBarStatCard(
              icon: const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              title: 'Жизни',
              value: '$lives/$maxLives',
              subtitle: showTimer ? 'Следующая через ${formatDuration(timeUntilNextLife)}' : 'Полный запас',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TopBarStatCard(
              icon: Image.asset(
                'assets/coins.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.monetization_on_rounded, color: Colors.amber),
              ),
              title: 'Монеты',
              value: '$coins',
              subtitle: 'Ваш баланс',
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarStatCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String value;
  final String subtitle;

  const _TopBarStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}