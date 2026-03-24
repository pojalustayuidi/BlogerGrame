import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/player_provider.dart';

class HintCounterWidget extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;

  const HintCounterWidget({super.key, this.onPressed});

  @override
  ConsumerState<HintCounterWidget> createState() => HintCounterWidgetState();
}

class HintCounterWidgetState extends ConsumerState<HintCounterWidget> {

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerProvider);

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
                  '${playerAsync.valueOrNull?.hints ?? 0}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void refresh() {
    setState(() {});
  }
}