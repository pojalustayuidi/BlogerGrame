import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/prufani_theme.dart';
import '../../economy/domain/economy_models.dart';
import '../domain/game_models.dart';
import 'game_ui_logic.dart';

const _deep = PrufaniColors.ink;

/// A compact game-only header: house, pack, level, lives and tries.
class PrufaniPlayHeader extends StatelessWidget {
  const PrufaniPlayHeader(
      {super.key,
      required this.onBack,
      required this.attempt,
      this.wallet,
      this.exitEnabled = true});
  final VoidCallback onBack;
  final PuzzleAttempt attempt;
  final GameWallet? wallet;
  final bool exitEnabled;
  @override
  Widget build(BuildContext context) {
    final title = switch (attempt.category) {
      'bloggers' => 'Блогеры',
      'tiktokers' => 'Тиктокеры',
      _ => 'Стримеры',
    };
    final total = attempt.layout.where((c) => c.isLetter).length;
    final filled = attempt.layout.where((c) => c.isLetter && c.isFilled).length;
    final fraction = total == 0 ? 0.0 : filled / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      decoration: BoxDecoration(
          color: const Color(0xFFF4E8FF),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFFE3CEF9))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                  key: const ValueKey('game-home'),
                  onTap: exitEnabled ? onBack : null,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                      width: 43,
                      height: 43,
                      child: Icon(Icons.home_rounded,
                          size: 26, color: PrufaniColors.primaryDark)))),
          const SizedBox(width: 7),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: PrufaniColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900)),
                Text('Уровень ${attempt.levelNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: PrufaniColors.primaryDark,
                        fontWeight: FontWeight.w800)),
              ])),
          _MiniGamePill(
              image: PrufaniAssets.heart,
              value:
                  wallet == null ? '—' : '${wallet!.lives}/${wallet!.maxLives}',
              semantics: 'Жизни'),
          const SizedBox(width: 4),
          _MiniGamePill(
              image: 'assets/prufani/icons/results/mistakes.png',
              value: '${attempt.triesRemaining}/${attempt.triesPerLife}',
              semantics: 'Попытки',
              caption: 'ПОПЫТКИ'),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0).toDouble(),
                minHeight: 5,
                color: PrufaniColors.yellow,
                backgroundColor: const Color(0xFFDCC7F8))),
      ]),
    );
  }
}

class _MiniGamePill extends StatelessWidget {
  const _MiniGamePill({
    required this.image,
    required this.value,
    required this.semantics,
    this.caption,
  });

  final String image;
  final String value;
  final String semantics;
  final String? caption;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$semantics: $value',
        child: Container(
          constraints: const BoxConstraints(minWidth: 50, maxWidth: 74),
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEFF),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white, width: 1.3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1D7641BA),
                  blurRadius: 8,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(image, width: 20, height: 22),
            const SizedBox(width: 3),
            Flexible(
              child: caption == null
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _deep)),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text(value,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _deep)),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(caption!,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 7.2,
                                      fontWeight: FontWeight.w800,
                                      color: PrufaniColors.primaryDark))),
                        ]),
            ),
          ]),
        ),
      );
}

class PrufaniGameLevelRibbon extends StatelessWidget {
  const PrufaniGameLevelRibbon({super.key, required this.attempt});
  final PuzzleAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final title = switch (attempt.category) {
      'bloggers' => 'Блогеры',
      'tiktokers' => 'Тиктокеры',
      _ => 'Стримеры',
    };
    final categoryImage = switch (attempt.category) {
      'bloggers' => PrufaniAssets.bloggers,
      'tiktokers' => PrufaniAssets.tiktokers,
      _ => PrufaniAssets.streamers,
    };
    final total = attempt.layout.where((x) => x.isLetter).length;
    final complete =
        attempt.layout.where((x) => x.isLetter && x.isFilled).length;
    final fraction = total == 0 ? 0.0 : complete / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9D62F0), Color(0xFF6133C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E7146BD), blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Image.asset(categoryImage,
              width: 38, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 9),
          Expanded(
              child: Text('$title · Уровень ${attempt.levelNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17))),
          Text('${(fraction * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 7,
            color: const Color(0x745323A6),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              duration: const Duration(milliseconds: 240),
              widthFactor: fraction.clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFEF8A), Color(0xFFFFC62B)]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// This is a layout of independent physical cells, not a per-number mapping.
/// Individual cells remain editable even when their cipher numbers repeat.
class PrufaniCipherBoard extends StatelessWidget {
  const PrufaniCipherBoard({
    super.key,
    required this.attempt,
    required this.selectedPosition,
    required this.onSelect,
    this.wrongPosition,
    this.feedbackPosition,
    this.feedbackLetter,
    this.cellAnchors,
    this.enabled = true,
  });

  final PuzzleAttempt attempt;
  final int? selectedPosition;
  final int? wrongPosition;
  final int? feedbackPosition;
  final String? feedbackLetter;
  final Map<int, GlobalKey>? cellAnchors;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final completedNumbers = completedCipherNumbers(attempt);
    final remaining = remainingCipherNumberCount(attempt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A8159BC), blurRadius: 15, offset: Offset(0, 7)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.format_quote_rounded,
              color: PrufaniColors.primary, size: 22),
          const SizedBox(width: 4),
          const Expanded(
              child: Text('РАЗГАДАЙ ЦИТАТУ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: PrufaniColors.primaryDark,
                      letterSpacing: .55,
                      fontWeight: FontWeight.w900))),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Text('Осталось чисел: $remaining',
                key: ValueKey('remaining-$remaining'),
                style: const TextStyle(
                    fontSize: 10,
                    color: PrufaniColors.primaryDark,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final tileWidth = ((width - 30) / 9).clamp(24.0, 37.0).toDouble();
          final tileHeight = tileWidth * 1.51;
          const betweenCells = 3.0;
          final maxWordCells =
              ((width + betweenCells) / (tileWidth + betweenCells))
                  .floor()
                  .clamp(1, 100)
                  .toInt();
          final words = _puzzleWords(attempt.layout, maxWordCells);
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 9,
              children: [
                for (final word in words)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < word.length; i++) ...[
                      if (word[i].isLetter)
                        _CipherTile(
                          key: ValueKey('cipher-cell-${word[i].position}'),
                          cellAnchor: cellAnchors?[word[i].position],
                          cell: word[i],
                          width: tileWidth,
                          height: tileHeight,
                          selected: word[i].position == selectedPosition,
                          sameNumber: false,
                          hideNumber: completedNumbers.contains(word[i].number),
                          wrong: word[i].position == wrongPosition,
                          previewLetter: word[i].position == feedbackPosition
                              ? feedbackLetter
                              : null,
                          onTap: !enabled || !canEditCell(word[i])
                              ? null
                              : () => onSelect(word[i].position),
                        )
                      else
                        SizedBox(
                          width: 10,
                          height: tileHeight,
                          child: Center(
                              child: Text(word[i].separator ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: _deep,
                                      fontWeight: FontWeight.w900))),
                        ),
                      if (i != word.length - 1)
                        const SizedBox(width: betweenCells),
                    ],
                  ]),
              ],
            ),
          );
        }),
      ]),
    );
  }
}

/// Keep words together when they fit. Only very long words are split into
/// segments, preventing a horizontal RenderFlex overflow on narrow phones.
List<List<PuzzleCell>> _puzzleWords(List<PuzzleCell> layout, int maxCells) {
  final words = <List<PuzzleCell>>[];
  var current = <PuzzleCell>[];
  void flush() {
    if (current.isNotEmpty) words.add(current);
    current = <PuzzleCell>[];
  }

  for (final cell in layout) {
    if (!cell.isLetter &&
        (cell.separator == ' ' ||
            cell.separator == '\n' ||
            cell.separator == '\r' ||
            cell.separator == null)) {
      flush();
      continue;
    }
    if (current.length >= maxCells) flush();
    current.add(cell);
  }
  flush();
  return words;
}

class _CipherTile extends StatefulWidget {
  const _CipherTile({
    super.key,
    required this.cell,
    required this.width,
    required this.height,
    required this.selected,
    required this.sameNumber,
    required this.hideNumber,
    required this.wrong,
    required this.onTap,
    this.previewLetter,
    this.cellAnchor,
  });
  final PuzzleCell cell;
  final double width;
  final double height;
  final bool selected;
  final bool sameNumber;
  final bool hideNumber;
  final bool wrong;
  final String? previewLetter;
  final GlobalKey? cellAnchor;
  final VoidCallback? onTap;

  @override
  State<_CipherTile> createState() => _CipherTileState();
}

class _CipherTileState extends State<_CipherTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reaction;
  bool _lastWasWrong = false;

  @override
  void initState() {
    super.initState();
    _reaction = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 310));
  }

  @override
  void didUpdateWidget(covariant _CipherTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wrong && !oldWidget.wrong) {
      _lastWasWrong = true;
      _reaction.forward(from: 0);
    } else if (widget.cell.isFilled && !oldWidget.cell.isFilled) {
      _lastWasWrong = false;
      _reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reaction,
      child: _tile(context),
      builder: (context, child) {
        final t = _reaction.value;
        final shake =
            _lastWasWrong ? math.sin(t * math.pi * 6) * (1 - t) * 5.0 : 0.0;
        final pop = !_lastWasWrong && _reaction.isAnimating
            ? 1 + math.sin(t * math.pi) * .09
            : 1.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(scale: pop, child: child),
        );
      },
    );
  }

  Widget _tile(BuildContext context) {
    final cell = widget.cell;
    final given = cell.given != null;
    final filled = cell.isFilled;
    final visible = cell.given ?? cell.letter ?? widget.previewLetter ?? '';
    final bg = widget.wrong
        ? const Color(0xFFFFD5DE)
        : widget.selected
            ? const Color(0xFF8558E0)
            : widget.sameNumber
                ? const Color(0xFFFFE9AB)
                : given
                    ? const Color(0xFFDFF9EE)
                    : cell.hinted
                        ? const Color(0xFFE7DAFF)
                        : filled
                            ? const Color(0xFFE4FFF1)
                            : Colors.white;
    final fg = widget.selected && !widget.wrong ? Colors.white : _deep;
    final border = widget.wrong
        ? const Color(0xFFE65B78)
        : widget.selected
            ? const Color(0xFF5F35C5)
            : widget.sameNumber
                ? const Color(0xFFF4B83F)
                : const Color(0xFFD9C7F2);
    return Semantics(
      button: widget.onTap != null,
      selected: widget.selected,
      label: 'Клетка ${cell.position + 1}, '
          'номер ${cell.number ?? 0}, '
          '${widget.hideNumber ? 'номер разгадан' : filled ? 'заполнена' : 'пустая'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            key: widget.cellAnchor,
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: border,
                  width: widget.selected || widget.sameNumber ? 2 : 1),
              boxShadow: [
                BoxShadow(
                    color: widget.selected
                        ? const Color(0x4C7649D8)
                        : widget.sameNumber
                            ? const Color(0x36E8A82B)
                            : const Color(0x268054B5),
                    blurRadius: widget.selected ? 8 : 5,
                    offset: const Offset(0, 3)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: Center(
                        child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 190),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                      scale:
                          Tween<double>(begin: .78, end: 1).animate(animation),
                      child: FadeTransition(opacity: animation, child: child)),
                  child: FittedBox(
                    key: ValueKey('$visible:${widget.wrong}:$filled'),
                    fit: BoxFit.scaleDown,
                    child: Text(
                        visible.isEmpty && widget.selected ? '—' : visible,
                        style: TextStyle(
                            color: fg,
                            fontSize: math.min(22, widget.width * .64),
                            fontWeight: FontWeight.w900)),
                  ),
                ))),
                SizedBox(
                  height: 11,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 210),
                    child: widget.hideNumber
                        ? const SizedBox(key: ValueKey('number-hidden'))
                        : Text('${cell.number ?? ''}',
                            key: const ValueKey('number-visible'),
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1,
                                color: widget.selected && !widget.wrong
                                    ? Colors.white
                                    : PrufaniColors.primaryDark,
                                fontWeight: FontWeight.w800)),
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

/// A key changes color only when its letter has a confirmed server cell.
/// Yellow = some physical occurrences remain unsolved; green = all solved.
class PrufaniKeyboard extends StatelessWidget {
  const PrufaniKeyboard({
    super.key,
    required this.onKey,
    required this.enabled,
    this.attempt,
  });

  final ValueChanged<String> onKey;
  final bool enabled;
  final PuzzleAttempt? attempt;

  @override
  Widget build(BuildContext context) {
    final states = attempt == null
        ? const <String, PrufaniKeyProgress>{}
        : keyboardProgress(attempt!);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E0FF),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x259263D8), blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var rowIndex = 0;
            rowIndex < russianKeyboardRows.length;
            rowIndex++) ...[
          Row(children: [
            for (var i = 0; i < russianKeyboardRows[rowIndex].length; i++) ...[
              Expanded(
                  child: _LetterKey(
                letter: russianKeyboardRows[rowIndex][i],
                enabled: enabled,
                progress: states[russianKeyboardRows[rowIndex][i]] ??
                    PrufaniKeyProgress.unknown,
                onTap: () => onKey(russianKeyboardRows[rowIndex][i]),
              )),
              if (i != russianKeyboardRows[rowIndex].length - 1)
                const SizedBox(width: 3),
            ],
          ]),
          if (rowIndex != russianKeyboardRows.length - 1)
            const SizedBox(height: 6),
        ],
        const SizedBox(height: 7),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _KeyLegend(color: Color(0xFFFFE3A0), label: 'Есть ещё клетки'),
          SizedBox(width: 12),
          _KeyLegend(color: Color(0xFFD6F4E5), label: 'Все заполнены'),
        ]),
      ]),
    );
  }
}

class _KeyLegend extends StatelessWidget {
  const _KeyLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFABD7)))),
          const SizedBox(width: 4),
          Text(label,
              maxLines: 1,
              style: const TextStyle(
                  color: PrufaniColors.primaryDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

class _LetterKey extends StatefulWidget {
  const _LetterKey({
    required this.letter,
    required this.enabled,
    required this.progress,
    required this.onTap,
  });
  final String letter;
  final bool enabled;
  final PrufaniKeyProgress progress;
  final VoidCallback onTap;

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final complete = widget.progress == PrufaniKeyProgress.completed;
    final partial = widget.progress == PrufaniKeyProgress.partial;
    final background = complete
        ? const Color(0xFFD6F4E5)
        : partial
            ? const Color(0xFFFFE3A0)
            : Colors.white;
    final foreground = complete ? const Color(0xFF277850) : PrufaniColors.ink;
    final border = complete
        ? const Color(0xFF83D3AE)
        : partial
            ? const Color(0xFFFFC846)
            : const Color(0xFFE3D5F5);
    final active = widget.enabled && !complete;
    return Semantics(
      label: 'Буква ${widget.letter}, '
          '${complete ? 'все заполнены' : partial ? 'частично заполнена' : 'не открыта'}',
      button: true,
      enabled: active,
      child: AnimatedScale(
        scale: _pressed && active ? .9 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            key: ValueKey('keyboard-${widget.letter}'),
            onTap: active ? widget.onTap : null,
            onHighlightChanged: (value) {
              if (mounted) setState(() => _pressed = value);
            },
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: border, width: partial || complete ? 1.5 : 1),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x167247A0),
                      blurRadius: 3,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Stack(children: [
                Center(
                    child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.letter,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: widget.enabled
                              ? foreground
                              : foreground.withValues(alpha: .6))),
                )),
                if (complete)
                  const Positioned(
                      right: 1,
                      top: 1,
                      child: Icon(Icons.check_rounded,
                          size: 9, color: Color(0xFF277850))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class PrufaniGameToolbar extends StatelessWidget {
  const PrufaniGameToolbar(
      {super.key,
      required this.onHint,
      required this.onNotes,
      required this.wallet,
      required this.enabled,
      required this.attempt});
  final VoidCallback? onHint;
  final VoidCallback? onNotes;
  final GameWallet? wallet;
  final bool enabled;
  final PuzzleAttempt attempt;

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
              child: _ToolChip(
            icon: PrufaniAssets.bulb,
            title: 'Подсказка',
            subtitle: wallet == null ? '—' : '${wallet!.hints} шт.',
            onTap: enabled ? onHint : null,
            background: const Color(0xFFFFEFCB),
          )),
          const SizedBox(width: 9),
          Expanded(
              child: _ToolChip(
            icon: 'assets/prufani/icons/features/notebook.png',
            title: 'Блокнот',
            subtitle: 'Догадки',
            onTap: enabled ? onNotes : null,
            background: const Color(0xFFECE0FF),
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.cancel_outlined,
              color: PrufaniColors.pink, size: 17),
          const SizedBox(width: 5),
          Expanded(
              child: Text(
                  'Ошибки: ${attempt.mistakes} · '
                  'до потери жизни: ${attempt.triesRemaining}/${attempt.triesPerLife}',
                  maxLines: 2,
                  style: const TextStyle(
                      color: PrufaniColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5))),
        ]),
      ]);
}

class _ToolChip extends StatelessWidget {
  const _ToolChip(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      required this.background});
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color background;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 53,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white, width: 1.3),
            ),
            child: Row(children: [
              Image.asset(icon, width: 32, height: 34, fit: BoxFit.contain),
              const SizedBox(width: 5),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(title,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: _deep))),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: PrufaniColors.primaryDark, fontSize: 10.5)),
                  ])),
              const Icon(Icons.chevron_right_rounded,
                  color: PrufaniColors.primaryDark, size: 19),
            ]),
          ),
        ),
      );
}
