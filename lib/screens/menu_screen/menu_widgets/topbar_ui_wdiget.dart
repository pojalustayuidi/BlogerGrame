import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final int lives;
  final int coins;
  final int maxLives;
  final Duration timeUntilNextLife;

  const TopBar({
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.08;
    final verticalPadding = screenWidth * 0.04;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF0DC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: lives >= 1 ? Colors.red : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 11),
                  Text(
                    '$lives/$maxLives',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (lives < maxLives && timeUntilNextLife > Duration.zero)
                Padding(
                  padding: const EdgeInsets.only(left: 35, top: 4),
                  child: Text(
                    formatDuration(timeUntilNextLife),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),

          Row(
            children: [
              Image.asset(
                'assets/coins.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on),
              ),
              const SizedBox(width: 8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}