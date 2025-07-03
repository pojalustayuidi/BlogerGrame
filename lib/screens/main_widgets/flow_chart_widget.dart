// lib/screens/main_widgets/flow_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class PlayerStatsWidget extends StatelessWidget {
  final int totalLevels;
  final int completedLevels;

  const PlayerStatsWidget({
    Key? key,
    required this.totalLevels,
    required this.completedLevels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percent = totalLevels == 0 ? 0 : completedLevels / totalLevels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 20.0,
          percent: percent.clamp(0.0, 1.0),
          center: Text(
            '${(percent * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[300]!,
          progressColor: Colors.green,
          barRadius: const Radius.circular(8),
          animation: true,
        ),
        const SizedBox(height: 8),
        Text('Решено: $completedLevels из $totalLevels уровней'),
      ],
    );
  }
}
