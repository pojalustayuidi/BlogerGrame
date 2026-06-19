import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/level_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../services/api/player_service.dart';
import '../../../services/models/level.dart';
import '../../menu_screen/menu_screen.dart';

class CustomLevelAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int levelId;
  final int errorCount;
  final List<Level> allLevels;
  final Level currentLevel;
  final int hints;
  final VoidCallback onHintPressed;

  const CustomLevelAppBar({
    super.key,
    required this.levelId,
    required this.errorCount,
    required this.allLevels,
    required this.currentLevel,
    required this.hints,
    required this.onHintPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(108);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final sideSize = width < 360 ? 42.0 : 46.0;
    final isDanger = errorCount >= 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 8),
            color: Color(0x335B8DEF),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            width < 360 ? 12 : 16,
            10,
            width < 360 ? 12 : 16,
            14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TopIconButton(
                icon: Icons.home_rounded,
                size: sideSize,
                onTap: () async {
                  await PlayerService.updateProgress(currentLevel.id, 0);

                  ref.invalidate(playerProvider);
                  ref.invalidate(levelsProvider);

                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(
                          levels: allLevels,
                          currentLevel: currentLevel,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdaptiveCenterCard(
                  levelId: levelId,
                  errorCount: errorCount,
                  isDanger: isDanger,
                ),
              ),
              const SizedBox(width: 10),
              _HintButton(
                hints: hints,
                size: sideSize,
                onTap: onHintPressed,
              ),
              const SizedBox(width: 6),
              _TopIconButton(
                icon: Icons.help_outline_rounded,
                size: sideSize,
                onTap: () {
                  _showFaq(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showFaq(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FaqBottomSheet(),
  );
}

class _AdaptiveCenterCard extends StatelessWidget {
  final int levelId;
  final int errorCount;
  final bool isDanger;

  const _AdaptiveCenterCard({
    required this.levelId,
    required this.errorCount,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final horizontalPadding = compact ? 12.0 : 14.0;
        final verticalPadding = compact ? 8.0 : 10.0;
        final titleFont = compact ? 16.0 : 18.0;
        final subtitleFont = compact ? 11.0 : 12.0;
        final iconSize = compact ? 18.0 : 20.0;
        final infoSize = compact ? 32.0 : 36.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: infoSize,
                height: infoSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Уровень $levelId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFont,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ошибки $errorCount/5',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subtitleFont,
                        fontWeight: FontWeight.w700,
                        color: isDanger
                            ? const Color(0xFFFFE4E6)
                            : Colors.white.withOpacity(0.95),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MistakesDots(
                      errorCount: errorCount,
                      isDanger: isDanger,
                      compact: compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _HintButton extends StatelessWidget {
  final int hints;
  final double size;
  final VoidCallback onTap;

  const _HintButton({
    required this.hints,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHints = hints > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size + 8, // чуть шире — влезает счётчик
        height: size,
        decoration: BoxDecoration(
          color: hasHints
              ? Colors.white.withOpacity(0.22)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasHints
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: hasHints ? Colors.amber : Colors.white38,
              size: size * 0.44,
            ),
            const SizedBox(width: 3),
            Text(
              '$hints',
              style: TextStyle(
                color: hasHints ? Colors.white : Colors.white38,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  State<_TopIconButton> createState() => _TopIconButtonState();
}

class _TopIconButtonState extends State<_TopIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _MistakesDots extends StatelessWidget {
  final int errorCount;
  final bool isDanger;
  final bool compact;

  const _MistakesDots({
    required this.errorCount,
    required this.isDanger,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 6.0 : 7.0;
    final spacing = compact ? 4.0 : 5.0;

    return Wrap(
      spacing: spacing,
      children: List.generate(5, (index) {
        final isUsed = index < errorCount;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isUsed
                ? const Color(0xFFFFD4D8)
                : Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(999),
            boxShadow: isUsed
                ? [
              BoxShadow(
                blurRadius: 6,
                offset: const Offset(0, 2),
                color: const Color(0xFFFFD4D8).withOpacity(0.30),
              ),
            ]
                : null,
          ),
        );
      }),
    );
  }
}

class _FaqBottomSheet extends StatelessWidget {
  const _FaqBottomSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const _FaqHeader(),
                const SizedBox(height: 14),
                const _FaqCarousel(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF5B8DEF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Понятно',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqHeader extends StatelessWidget {
  const _FaqHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF5B8DEF),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Как играть',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Листай карточки вправо',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqCarousel extends StatefulWidget {
  const _FaqCarousel();

  @override
  State<_FaqCarousel> createState() => _FaqCarouselState();
}

class _FaqCarouselState extends State<_FaqCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  final List<_FaqData> items = const [
    _FaqData(
      icon: Icons.pin_outlined,
      title: 'Цифра = буква',
      content:
      'Каждая цифра соответствует одной и той же букве.\n\n'
          'Например, если 9 = «е», то во всех клетках с цифрой 9 будет буква «е».',
    ),
    _FaqData(
      icon: Icons.keyboard_rounded,
      title: 'Синяя буква',
      content:
      'Синяя буква на клавиатуре означает, что эта буква уже используется во фразе где-то ещё.\n\n'
          'Так проще замечать повторения и быстрее находить нужные буквы.',
    ),
    _FaqData(
      icon: Icons.lightbulb_rounded,
      title: 'С чего начинать',
      content:
      'Сначала заполняй те буквы, шифр которых ты уже знаешь.\n\n'
          'После этого станет легче угадывать остальные символы по словам и повторам.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() => _page = index);
            },
            itemBuilder: (context, index) {
              final item = items[index];

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;

                  if (_controller.position.hasContentDimensions) {
                    final page = _controller.page ?? _page.toDouble();
                    final diff = (page - index).abs();
                    scale = (1 - (diff * 0.06)).clamp(0.94, 1.0);
                  }

                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _FaqCard(
                    icon: item.icon,
                    title: item.title,
                    content: item.content,
                    isActive: index == _page,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _DotsIndicator(
          count: items.length,
          current: _page,
        ),
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final bool isActive;

  const _FaqCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            blurRadius: isActive ? 20 : 10,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(isActive ? 0.08 : 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5B8DEF),
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(
                Icons.swipe_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(width: 6),
              Text(
                'Листай вправо',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotsIndicator({
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: List.generate(count, (index) {
        final active = index == current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF5B8DEF)
                : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _FaqData {
  final IconData icon;
  final String title;
  final String content;

  const _FaqData({
    required this.icon,
    required this.title,
    required this.content,
  });
}