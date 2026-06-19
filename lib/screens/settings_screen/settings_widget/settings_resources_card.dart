import 'package:blogergrame/providers/player_provider.dart';
import 'package:blogergrame/services/api/player_service.dart';
import 'package:flutter/material.dart';


class SettingsResourcesCard extends StatelessWidget {
  final PlayerData player;

  const SettingsResourcesCard({
    super.key,
    required this.player,
  });

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
                child: ResourceStat(
                  icon: Image.asset('assets/coins.png', width: 26, height: 26),
                  value: player.coins,
                  label: 'Монет',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResourceStat(
                  icon: Image.asset(
                    'assets/icon_hint.png',
                    width: 26,
                    height: 26,
                  ),
                  value: player.hints,
                  label: 'Подсказок',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResourceStat(
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

class ResourceStat extends StatelessWidget {
  final Widget icon;
  final int value;
  final String label;

  const ResourceStat({
    super.key,
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