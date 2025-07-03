import 'package:flutter/material.dart';
import '../../../servises/player_sevice.dart';
class HintCounterWidget extends StatefulWidget {
  final VoidCallback? onPressed;

  const HintCounterWidget({super.key, this.onPressed});

  @override
  State<HintCounterWidget> createState() => HintCounterWidgetState();
}

class HintCounterWidgetState extends State<HintCounterWidget> {
  int _hintCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHints();
  }

  Future<void> loadHints() async {
    final stats = await PlayerService.getPlayerStats();
    setState(() {
      _hintCount = stats?['hints'] ?? 0;
      _isLoading = false;
    });
  }

  void refresh() => loadHints(); // Публичный метод обновления

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_hintCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
