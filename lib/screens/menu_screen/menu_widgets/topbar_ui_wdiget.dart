import 'package:flutter/material.dart';

class TopBar extends StatefulWidget {
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

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
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
                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.01),
                    child: Icon(
                      Icons.favorite,
                      color:
                          widget.lives >= 1 ? Colors.red : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),

                  SizedBox(width: 11,),

                  Text(
                    '${widget.lives}/5',
                    style: const TextStyle(fontSize: 24, fontFamily: 'baloo'),
                  ),
                  SizedBox(width: screenWidth * 0.21),
                  Image.asset(
                    'assets/coins.png',
                    width: 24,
                    height: 24,
                  ),
                  Text(
                    ' ${widget.coins}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'baloo',
                    ),
                  ),
                ],
              ),
              if (widget.lives < 5 && widget.timeUntilNextLife > Duration.zero)
                Padding(
                  padding: EdgeInsets.only(top: 1.0, left: screenWidth * 0.05),
                  child: Text(
                    formatDuration(widget.timeUntilNextLife),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontFamily: 'baloo',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
