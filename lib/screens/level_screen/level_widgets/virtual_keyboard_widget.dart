import 'package:flutter/material.dart';

class VirtualKeyboardWidget extends StatefulWidget {
  final void Function(String, void Function() onLetterAccepted) onLetterPressed;
  final List<int> correctIndices;
  final List<int> revealed;
  final Map<String, int> letterMap;
  final List<String?> userInput;
  final String fullPhrase;

  const VirtualKeyboardWidget({
    super.key,
    required this.onLetterPressed,
    required this.correctIndices,
    required this.revealed,
    required this.letterMap,
    required this.userInput,
    required this.fullPhrase,
  });

  @override
  State<VirtualKeyboardWidget> createState() => _VirtualKeyboardWidgetState();
}

class _VirtualKeyboardWidgetState extends State<VirtualKeyboardWidget> {
  bool isLetterCompleted(String letter) {
    final number = widget.letterMap[letter];
    if (number == null) return false;

    final indices = widget.fullPhrase
        .toLowerCase()
        .split('')
        .asMap()
        .entries
        .where((e) => widget.letterMap[e.value] == number)
        .map((e) => e.key)
        .toList();

    return indices.every(
          (index) =>
      widget.revealed.contains(index) ||
          (widget.userInput[index]?.toLowerCase() ==
              widget.fullPhrase[index].toLowerCase()),
    );
  }

  bool isLetterUsed(String letter) {
    final number = widget.letterMap[letter];
    if (number == null) return false;

    final indices = widget.fullPhrase
        .toLowerCase()
        .split('')
        .asMap()
        .entries
        .where((e) => widget.letterMap[e.value] == number)
        .map((e) => e.key)
        .toList();

    return indices.any(
          (index) =>
      widget.revealed.contains(index) ||
          (widget.userInput[index]?.toLowerCase() ==
              widget.fullPhrase[index].toLowerCase()),
    );
  }

  Widget buildRow(List<String> rowLetters) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final buttonWidth = (availableWidth / rowLetters.length) - 4;
          final buttonHeight = buttonWidth * 1.34;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rowLetters.map((letter) {
              final lower = letter.toLowerCase();
              final completed = isLetterCompleted(lower);
              final used = isLetterUsed(lower);

              Color bgColor = Colors.white;
              Color fgColor = const Color(0xFF111827);
              Color borderColor = const Color(0xFFE5E7EB);

              if (completed) {
                bgColor = const Color(0xFFE5E7EB);
                fgColor = const Color(0xFF6B7280);
                borderColor = const Color(0xFFD1D5DB);
              } else if (used) {
                bgColor = const Color(0xFFEEF4FF);
                fgColor = const Color(0xFF5B8DEF);
                borderColor = const Color(0xFFBFDBFE);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _AnimatedKey(
                  letter: letter,
                  width: buttonWidth,
                  height: buttonHeight,
                  bgColor: bgColor,
                  fgColor: fgColor,
                  borderColor: borderColor,
                  disabled: completed,
                  onPressed: completed
                      ? null
                      : () => widget.onLetterPressed(letter, () {}),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = screenHeight * 0.29;

    const row1 = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й'];
    const row2 = ['К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф'];
    const row3 = ['Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я'];

    return Container(
      height: keyboardHeight,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          buildRow(row1),
          const SizedBox(height: 8),
          buildRow(row2),
          const SizedBox(height: 8),
          buildRow(row3),
        ],
      ),
    );
  }
}

/// Отдельный виджет для одной клавиши с анимацией нажатия
class _AnimatedKey extends StatefulWidget {
  final String letter;
  final double width;
  final double height;
  final Color bgColor;
  final Color fgColor;
  final Color borderColor;
  final bool disabled;
  final VoidCallback? onPressed;

  const _AnimatedKey({
    required this.letter,
    required this.width,
    required this.height,
    required this.bgColor,
    required this.fgColor,
    required this.borderColor,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_AnimatedKey> createState() => _AnimatedKeyState();
}

class _AnimatedKeyState extends State<_AnimatedKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
      vsync: this,
    );

    // При нажатии сжимается до 0.88, при отпускании возвращается с overshoot
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 100,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.disabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
            boxShadow: widget.disabled
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.letter,
              style: TextStyle(
                fontSize: widget.width * 0.42,
                fontWeight: FontWeight.w700,
                color: widget.fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}