import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prufani_theme.dart';
import '../../../core/di/backend_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../home/presentation/home_screen.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/game_models.dart';
import 'game_play_controller.dart';
import 'game_ui_logic.dart';
import 'game_widgets.dart';

/// Full-screen gameplay. The existing category -> levels route pushes this
/// page; no legacy whole-phrase-check API is used.
class PrufaniGameScreen extends ConsumerWidget {
  const PrufaniGameScreen({super.key, required this.initialAttempt});

  final PuzzleAttempt initialAttempt;

  Future<void> _confirmHint(BuildContext context,
      PrufaniGameController controller, GamePlayState state) async {
    if (!state.canType) return;
    if (state.wallet != null && state.wallet!.hints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Подсказки закончились. Загляни в магазин!')));
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PrufaniColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Раскрыть букву?'),
        content: const Text(
          'Подсказка откроет только выбранную клетку. '
          'Одна подсказка будет списана сервером.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Раскрыть')),
        ],
      ),
    );
    if (approved == true) await controller.revealSelected();
  }

  Future<void> _openNotebook(BuildContext context,
      PrufaniGameController controller, GamePlayState state) async {
    final cell = selectedCell(state.attempt, state.selectedPosition);
    if (cell?.number == null) return;
    final number = cell!.number!;
    PuzzleNote? existing;
    for (final note in state.attempt.notes) {
      if (note.number == number) {
        existing = note;
        break;
      }
    }
    final letterController =
        TextEditingController(text: existing?.letter ?? '');
    final commentController =
        TextEditingController(text: existing?.comment ?? '');
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: PrufaniColors.cream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (sheetContext) {
          var saving = false;
          var error = '';
          return StatefulBuilder(
            builder: (context, setSheetState) => Padding(
              padding: EdgeInsets.fromLTRB(21, 20, 21,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 25),
              child: SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Блокнот',
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: PrufaniColors.ink)),
                  const SizedBox(height: 6),
                  Text('Число $number · это догадка, не игровой ответ',
                      style: const TextStyle(
                          color: PrufaniColors.muted, fontSize: 12.5)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: letterController,
                    maxLength: 1,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Возможная буква (необязательно)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Заметка',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(error,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final raw = letterController.text.trim();
                                final letter = raw.isEmpty
                                    ? null
                                    : normalizedKeyboardLetter(raw);
                                if (raw.isNotEmpty && letter == null) {
                                  setSheetState(() =>
                                      error = 'Введи одну русскую букву.');
                                  return;
                                }
                                setSheetState(() {
                                  saving = true;
                                  error = '';
                                });
                                final saved = await controller.saveNote(
                                  number: number,
                                  letter: letter,
                                  comment: commentController.text.trim(),
                                );
                                if (saved && sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                } else if (sheetContext.mounted) {
                                  setSheetState(() {
                                    saving = false;
                                    error =
                                        'Не удалось сохранить. Проверь соединение.';
                                  });
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: PrufaniColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Сохранить заметку'),
                      )),
                ],
              )),
            ),
          );
        },
      );
    } finally {
      letterController.dispose();
      commentController.dispose();
    }
  }

  Future<void> _goHome(BuildContext context, WidgetRef ref,
      PrufaniGameController controller, GamePlayState state) async {
    if (!state.canLeave) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Дождись ответа сервера или повтори незавершённый ввод.')));
      return;
    }
    if (state.attempt.status == 'in_progress') {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  backgroundColor: PrufaniColors.cream,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23)),
                  title: const Text('Выйти из уровня?'),
                  content: const Text(
                      'Выход завершит текущий раунд и спишет 1 жизнь. '
                      'Чтобы не потерять прогресс, заверши цитату.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Остаться')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Выйти · −1 жизнь')),
                  ]));
      if (confirmed != true || !context.mounted) return;
      final success = await controller.forfeit();
      if (!success || !context.mounted) return;
    }
    ref.invalidate(homeOverviewProvider);
    Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const PrufaniHomeScreen()),
        (route) => false);
  }

  Future<void> _restart(BuildContext context, WidgetRef ref,
      PrufaniGameController controller) async {
    final fresh = await controller.restart();
    if (fresh == null || !context.mounted) return;
    try {
      final id = await ref.read(authRepositoryProvider).getPlayerId();
      await ref.read(homeAttemptStoreProvider).save(id, fresh);
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Не удалось сохранить новую попытку: $error')));
      return;
    }
    if (!context.mounted) return;
    ref.invalidate(homeOverviewProvider);
    ref.invalidate(catalogLevelsProvider(fresh.category));
    await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
            builder: (_) => PrufaniGameScreen(initialAttempt: fresh)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = prufaniGameProvider(initialAttempt);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final complete = state.isSolved;
    final ended = state.roundEnded;
    final hasPending = state.pending != null;
    final warning = state.message;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: PrufaniColors.cream,
          resizeToAvoidBottomInset: true,
          // The notebook, hint action and keyboard have their own fixed area.
          // Scrolling a long quote cannot move them off-screen.
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: complete
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FilledButton.icon(
                            onPressed: state.busy
                                ? null
                                : state.attempt.reveal == null
                                    ? controller.finishWithoutBonus
                                    : () => _goHome(
                                        context, ref, controller, state),
                            icon: Icon(state.attempt.reveal == null
                                ? Icons.check_circle_rounded
                                : Icons.home_rounded),
                            label: Text(state.attempt.reveal == null
                                ? 'Завершить уровень'
                                : 'На главную'),
                            style: FilledButton.styleFrom(
                              backgroundColor: PrufaniColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        )
                      : ended
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: state.busy ||
                                            (state.wallet?.lives ?? 0) == 0
                                        ? null
                                        : () =>
                                            _restart(context, ref, controller),
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: Text((state.wallet?.lives ?? 0) == 0
                                        ? 'Нет жизней · дождись восстановления'
                                        : 'Начать заново'),
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            PrufaniColors.primaryDark,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15)),
                                  )))
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              PrufaniGameToolbar(
                                attempt: state.attempt,
                                wallet: state.wallet,
                                enabled: state.canType,
                                onHint: () =>
                                    _confirmHint(context, controller, state),
                                onNotes: () =>
                                    _openNotebook(context, controller, state),
                              ),
                              const SizedBox(height: 5),
                              PrufaniKeyboard(
                                attempt: state.attempt,
                                enabled: state.canType,
                                onKey: controller.input,
                              ),
                            ]),
                ),
              ),
            ),
          ),
          body: Stack(children: [
            Positioned.fill(
              child: Image.asset(PrufaniAssets.background, fit: BoxFit.cover),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
                    child: Column(children: [
                      PrufaniPlayHeader(
                        onBack: () => _goHome(context, ref, controller, state),
                        wallet: state.wallet,
                        attempt: state.attempt,
                        exitEnabled: state.canLeave,
                      ),
                      if (state.initializing || state.busy) ...[
                        const SizedBox(height: 5),
                        const LinearProgressIndicator(
                            color: PrufaniColors.primary, minHeight: 3),
                      ],
                      if (warning != null) ...[
                        const SizedBox(height: 6),
                        _GameStatusBanner(
                          message: warning,
                          error: state.isError,
                          onRetry: hasPending || state.isError
                              ? (state.busy ? null : controller.retry)
                              : null,
                          retryLabel: hasPending ? 'Повторить' : 'Обновить',
                        ),
                      ] else if (hasPending) ...[
                        const SizedBox(height: 6),
                        _GameStatusBanner(
                          message: 'Ввод ожидает ответа сервера. '
                              'Повтори запрос с тем же ID.',
                          error: true,
                          onRetry: state.busy ? null : controller.retry,
                          retryLabel: 'Повторить',
                        ),
                      ],
                      if (!complete &&
                          state.wallet != null &&
                          state.wallet!.lives == 0) ...[
                        const SizedBox(height: 6),
                        const _NoLivesBanner(),
                      ],
                      const SizedBox(height: 8),
                      // A constrained viewport is the ONLY scrolling part of
                      // the active game page, with a visible right-side track.
                      Expanded(
                        child: complete
                            ? SingleChildScrollView(
                                child: _SolvedPanel(state: state))
                            : ended
                                ? SingleChildScrollView(
                                    child: _RoundEndedPanel(state: state))
                                : PrufaniBoardViewport(
                                    attempt: state.attempt,
                                    selectedPosition: state.selectedPosition,
                                    wrongPosition: state.wrongFlash
                                        ? state.feedbackPosition
                                        : null,
                                    feedbackPosition: state.feedbackPosition,
                                    feedbackLetter: state.feedbackLetter,
                                    enabled: !state.busy && !hasPending,
                                    onSelect: controller.select,
                                  ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Only the cipher board scrolls. The keyboard and action toolbar remain fixed.
/// Metrics are captured *after* layout and passed to a passive indicator.
/// This prevents a scroll-driven build from querying ScrollPosition while its
/// dimensions are being updated (the previous test could hit a null value).
class PrufaniBoardViewport extends StatefulWidget {
  const PrufaniBoardViewport({
    super.key,
    required this.attempt,
    required this.selectedPosition,
    required this.onSelect,
    this.wrongPosition,
    this.feedbackPosition,
    this.feedbackLetter,
    this.enabled = true,
  });

  final PuzzleAttempt attempt;
  final int? selectedPosition;
  final int? wrongPosition;
  final int? feedbackPosition;
  final String? feedbackLetter;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  State<PrufaniBoardViewport> createState() => _PrufaniBoardViewportState();
}

class _PrufaniBoardViewportState extends State<PrufaniBoardViewport> {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _cellAnchors = <int, GlobalKey>{};
  bool _hasOverflow = false;
  bool _updateScheduled = false;
  double _thumbFraction = 0.9;
  double _scrollFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _syncCellAnchors();
    _scheduleMetricsUpdate();
    _scrollSelectionIntoView();
  }

  @override
  void didUpdateWidget(covariant PrufaniBoardViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attempt != widget.attempt) {
      _syncCellAnchors();
      _scheduleMetricsUpdate();
    }
    if (oldWidget.selectedPosition != widget.selectedPosition) {
      _scrollSelectionIntoView();
    }
  }

  // Keys remain stable across server refreshes so reactions can animate and
  // automatic scroll can locate the newly selected physical cell.
  void _syncCellAnchors() {
    final positions = <int>{
      for (final cell in widget.attempt.layout)
        if (cell.isLetter) cell.position,
    };
    _cellAnchors.removeWhere((position, _) => !positions.contains(position));
    for (final position in positions) {
      _cellAnchors.putIfAbsent(
          position, () => GlobalKey(debugLabel: 'game-cell-$position'));
    }
  }

  void _scrollSelectionIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scroll.hasClients ||
          !_scroll.position.hasContentDimensions) return;
      final selected = widget.selectedPosition;
      if (selected == null) return;
      final target = _cellAnchors[selected]?.currentContext;
      if (target == null) return;
      // Does not scroll if the cell is already visible. When a long quote
      // moves the selection below the fold, gently reveal it in-place.
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: .4,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// Reading scroll metrics during build/layout is fragile. This is the only
  /// place that reads a ScrollPosition, and it runs after the frame is laid out.
  void _scheduleMetricsUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (!position.hasContentDimensions ||
          !position.hasViewportDimension ||
          !position.hasPixels) {
        return;
      }
      final maxExtent = position.maxScrollExtent;
      final viewport = position.viewportDimension;
      if (!maxExtent.isFinite || !viewport.isFinite || viewport <= 0) return;

      final overflowing = maxExtent > 2;
      final thumb = overflowing
          ? (viewport / (viewport + maxExtent)).clamp(0.16, 0.9).toDouble()
          : 0.9;
      final fraction = overflowing
          ? (position.pixels / maxExtent).clamp(0.0, 1.0).toDouble()
          : 0.0;

      if (_hasOverflow != overflowing ||
          (_thumbFraction - thumb).abs() > 0.001 ||
          (_scrollFraction - fraction).abs() > 0.001) {
        setState(() {
          _hasOverflow = overflowing;
          _thumbFraction = thumb;
          _scrollFraction = fraction;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) _scheduleMetricsUpdate();
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _scheduleMetricsUpdate();
            return false;
          },
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  key: const ValueKey('game-board-scroll'),
                  controller: _scroll,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PrufaniCipherBoard(
                      attempt: widget.attempt,
                      selectedPosition: widget.selectedPosition,
                      cellAnchors: _cellAnchors,
                      wrongPosition: widget.wrongPosition,
                      feedbackPosition: widget.feedbackPosition,
                      feedbackLetter: widget.feedbackLetter,
                      enabled: widget.enabled,
                      onSelect: widget.onSelect,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 8,
              child: AnimatedOpacity(
                opacity: _hasOverflow ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _BoardScrollTrack(
                  thumbFraction: _thumbFraction,
                  scrollFraction: _scrollFraction,
                ),
              ),
            ),
          ]),
        ),
      );
}

/// Pure visual indicator: no ScrollController/position reads in build.
class _BoardScrollTrack extends StatelessWidget {
  const _BoardScrollTrack({
    required this.thumbFraction,
    required this.scrollFraction,
  });

  final double thumbFraction;
  final double scrollFraction;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Индикатор прокрутки цитаты',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: LayoutBuilder(builder: (context, constraints) {
            final height = constraints.maxHeight;
            if (!height.isFinite || height <= 0) {
              return const SizedBox.shrink();
            }
            final fraction = thumbFraction.clamp(0.16, 0.9).toDouble();
            final thumbHeight = height * fraction;
            final top = (height - thumbHeight) *
                scrollFraction.clamp(0.0, 1.0).toDouble();
            return Stack(fit: StackFit.expand, children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D8F7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Positioned(
                key: const ValueKey('game-board-scroll-thumb'),
                top: top,
                left: 0,
                right: 1,
                height: thumbHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA97CF6), Color(0xFF6432CB)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ]);
          }),
        ),
      );
}

class _GameStatusBanner extends StatelessWidget {
  const _GameStatusBanner({
    required this.message,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Повторить',
  });

  final String message;
  final bool error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(9, 5, 5, 5),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFE9EF) : const Color(0xFFE4FFF1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          Icon(
              error
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: error ? const Color(0xFFBB3755) : const Color(0xFF279467),
              size: 18),
          const SizedBox(width: 6),
          Expanded(
              child: Text(message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: PrufaniColors.ink))),
          if (onRetry != null)
            TextButton(
                onPressed: onRetry,
                child: Text(retryLabel, style: const TextStyle(fontSize: 11))),
        ]),
      );
}

class _SolvedPanel extends StatelessWidget {
  const _SolvedPanel({required this.state});
  final GamePlayState state;
  @override
  Widget build(BuildContext context) {
    final reveal = state.attempt.reveal;
    final start = state.attempt.startedAt;
    final end = state.attempt.completedAt;
    final duration =
        start != null && end != null ? end.difference(start) : null;
    final time = duration == null
        ? null
        : '${duration.inMinutes.toString().padLeft(2, '0')}:'
            '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF4D8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2)),
      child: Column(children: [
        Image.asset('assets/prufani/illustrations/mascot_victory_small.png',
            height: 131, fit: BoxFit.contain),
        const Text('Уровень пройден!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: PrufaniColors.primaryDark)),
        const SizedBox(height: 12),
        if (reveal != null) ...[
          Text('«${reveal.quote}»',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: PrufaniColors.ink)),
          const SizedBox(height: 8),
          Text(reveal.creator ?? 'Автор не указан',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PrufaniColors.primaryDark)),
        ] else ...[
          const Text(
              'Цитата разгадана! Нажми «Завершить уровень», '
              'чтобы узнать автора. Дополнительный вопрос пока пропускаем.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: PrufaniColors.ink)),
        ],
        const SizedBox(height: 13),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (time != null)
                _StatChip(icon: Icons.timer_outlined, label: time),
              _StatChip(
                  icon: Icons.close_rounded,
                  label: 'Ошибки: ${state.attempt.mistakes}'),
              if (state.earnedCoins > 0)
                _StatChip(
                    icon: Icons.monetization_on_rounded,
                    label: '+${state.earnedCoins} монет'),
            ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: PrufaniColors.primaryDark),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: PrufaniColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]));
}

class _RoundEndedPanel extends StatelessWidget {
  const _RoundEndedPanel({required this.state});
  final GamePlayState state;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFFFE8EE),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: Colors.white, width: 2)),
      child: Column(children: [
        const Icon(Icons.favorite_border_rounded,
            size: 69, color: PrufaniColors.pink),
        const SizedBox(height: 12),
        const Text('Попытки закончились',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: PrufaniColors.primaryDark)),
        const SizedBox(height: 8),
        const Text(
            'Три ошибки — потеряна одна жизнь. '
            'Начни заново с чистого поля. Сохранение для особых режимов '
            'появится позже.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, height: 1.35, color: PrufaniColors.ink)),
        if ((state.wallet?.lives ?? 0) == 0) ...[
          const SizedBox(height: 9),
          const Text(
              'Жизни закончились. Вернись домой и дождись восстановления.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PrufaniColors.primaryDark)),
        ],
      ]));
}

class _NoLivesBanner extends StatelessWidget {
  const _NoLivesBanner();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5EF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Text(
            'Жизни закончились. Новые попытки будут доступны '
            'после восстановления жизни или покупки в магазине.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: PrufaniColors.ink,
                fontWeight: FontWeight.w700)),
      );
}
