import 'package:flutter/material.dart';
import '../../../services/models/level.dart';
import 'phrase_display_widget.dart';

class PhraseBoardCard extends StatefulWidget {
  final Level level;
  final List<String?> userInput;
  final int? selectedIndex;
  final List<int> incorrectIndices;
  final List<int> correctIndices;
  final List<int> completedNumbers;
  final void Function(int index) onSelect;

  const PhraseBoardCard({
    super.key,
    required this.level,
    required this.userInput,
    required this.selectedIndex,
    required this.incorrectIndices,
    required this.correctIndices,
    required this.completedNumbers,
    required this.onSelect,
  });

  @override
  State<PhraseBoardCard> createState() => _PhraseBoardCardState();
}

class _PhraseBoardCardState extends State<PhraseBoardCard> {
  final ScrollController _scrollController = ScrollController();
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void didUpdateWidget(covariant PhraseBoardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;
    final canScroll = _scrollController.position.maxScrollExtent > 0;
    if (canScroll != _canScroll) {
      setState(() => _canScroll = canScroll);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // scrollbar ширина + SizedBox между контентом и баром
    const scrollbarWidth = 6.0 + 10.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE6EEF9)),
                ),
                // LayoutBuilder ЗДЕСЬ — до ScrollView, получает конечную ширину
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // constraints.maxWidth здесь конечный — это ширина
                    // внутреннего контейнера минус его padding (14+14)
                    final availableWidth =
                        constraints.maxWidth - 14.0 - 14.0;

                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                      child: PhraseDisplayWidget(
                        level: widget.level,
                        userInput: widget.userInput,
                        selectedIndex: widget.selectedIndex,
                        incorrectIndices: widget.incorrectIndices,
                        correctIndices: widget.correctIndices,
                        completedNumbers: widget.completedNumbers,
                        onSelect: widget.onSelect,
                        availableWidth: availableWidth,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedOpacity(
            opacity: _canScroll ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: _MinimalScrollIndicator(controller: _scrollController),
          ),
        ],
      ),
    );
  }
}

class _MinimalScrollIndicator extends StatelessWidget {
  final ScrollController controller;

  const _MinimalScrollIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double topFraction = 0;
        double thumbFraction = 0.24;

        if (controller.hasClients) {
          final position = controller.position;
          final maxExtent = position.maxScrollExtent;

          if (maxExtent > 0) {
            final viewport = position.viewportDimension;
            thumbFraction =
                (viewport / (viewport + maxExtent)).clamp(0.18, 0.5);
            final progress = (position.pixels / maxExtent).clamp(0.0, 1.0);
            topFraction = progress * (1 - thumbFraction);
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final trackHeight = constraints.maxHeight;
            final thumbHeight = trackHeight * thumbFraction;
            final top = trackHeight * topFraction;

            return Container(
              width: 6,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: thumbHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFD8FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}