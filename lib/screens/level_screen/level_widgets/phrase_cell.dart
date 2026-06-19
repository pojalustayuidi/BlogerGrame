import 'dart:math' as math;
import 'package:flutter/material.dart';

class PhraseCell extends StatefulWidget {
  final int index;
  final String? value;
  final int? number;
  final bool isRevealed;
  final bool isSelected;
  final bool isIncorrect;
  final bool isCorrect;
  final bool isCompleted;
  final VoidCallback onTap;
  final double cellSize;

  const PhraseCell({
    super.key,
    required this.index,
    required this.value,
    required this.number,
    required this.isRevealed,
    required this.isSelected,
    required this.isIncorrect,
    required this.isCorrect,
    required this.isCompleted,
    required this.onTap,
    required this.cellSize,
  });

  @override
  State<PhraseCell> createState() => _PhraseCellState();
}

class _PhraseCellState extends State<PhraseCell>
    with TickerProviderStateMixin {
  // --- Shake (ошибка) ---
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // --- Bounce (правильная буква) ---
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  bool _wasIncorrect = false;
  bool _wasCorrect = false;

  @override
  void initState() {
    super.initState();

    // Shake: быстрое горизонтальное дрожание как в iOS
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Bounce: ячейка чуть вырастает и возвращается
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      // Быстро растём до 1.18
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      // Плавно возвращаемся с небольшим overshoot
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      // Финальное settling обратно в 1.0
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant PhraseCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Запускаем shake когда ячейка становится incorrect
    if (widget.isIncorrect && !_wasIncorrect) {
      _shakeController.forward(from: 0);
    }
    _wasIncorrect = widget.isIncorrect;

    // Запускаем bounce когда буква становится правильной
    if (widget.isCorrect && !_wasCorrect) {
      _bounceController.forward(from: 0);
    }
    _wasCorrect = widget.isCorrect;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  /// Shake смещение — синусоида затухающая по времени
  double _shakeOffset(double t) {
    // t от 0 до 1, амплитуда затухает, частота 3 колебания
    final amplitude = 6.0 * (1 - t); // затухание
    return amplitude * math.sin(t * math.pi * 6);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowNumber = widget.number != null && !widget.isCompleted;

    final cellHeight = widget.cellSize * 1.28;
    final radius = (widget.cellSize * 0.34).clamp(10.0, 15.0);
    final letterFontSize = (widget.cellSize * 0.52).clamp(16.0, 22.0);
    final numberFontSize = (widget.cellSize * 0.22).clamp(9.0, 11.0);
    final numberHeight = (widget.cellSize * 0.34).clamp(10.0, 14.0);

    // Цвета — те же что были
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF0F172A);

    List<BoxShadow> shadows = [
      BoxShadow(
        blurRadius: widget.cellSize * 0.18,
        offset: Offset(0, widget.cellSize * 0.09),
        color: Colors.black.withOpacity(0.03),
      ),
    ];

    if (widget.isIncorrect) {
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFFB91C1C);
    } else if (widget.isSelected) {
      bgColor = const Color(0xFFEEF4FF);
      borderColor = const Color(0xFF5B8DEF);
      textColor = const Color(0xFF2563EB);
      shadows = [
        BoxShadow(
          blurRadius: widget.cellSize * 0.3,
          offset: Offset(0, widget.cellSize * 0.12),
          color: const Color(0xFF5B8DEF).withOpacity(0.16),
        ),
      ];
    } else if (widget.isCompleted || widget.isCorrect || widget.isRevealed) {
      bgColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFFD8E2EE);
      textColor = const Color(0xFF0F172A);
    }

    return GestureDetector(
      onTap: widget.isRevealed || widget.isCorrect ? null : widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Shake обёртка ---
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final offset = _shakeOffset(_shakeAnimation.value);

              // --- Bounce обёртка ---
              return AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: Transform.scale(
                      scale: _bounceAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: widget.cellSize,
              height: cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 1.8 : 1.1,
                ),
                boxShadow: shadows,
              ),
              child: Text(
                widget.value?.toUpperCase() ?? '',
                style: TextStyle(
                  fontSize: letterFontSize,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
          SizedBox(height: widget.cellSize * 0.1),
          SizedBox(
            height: numberHeight,
            child: Text(
              shouldShowNumber ? widget.number.toString() : '',
              style: TextStyle(
                fontSize: numberFontSize,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}