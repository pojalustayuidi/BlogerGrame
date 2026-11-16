import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/di/backend_providers.dart';
import '../../core/theme/prufani_theme.dart';
import '../../features/home/presentation/home_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import 'startup_bootstrap.dart';

/// Single startup entry point. Does not use the legacy playerProvider.
/// A failed request keeps the secure refresh token untouched.
class PrufaniStartupGate extends ConsumerStatefulWidget {
  const PrufaniStartupGate({super.key});

  @override
  ConsumerState<PrufaniStartupGate> createState() => _PrufaniStartupGateState();
}

class _PrufaniStartupGateState extends ConsumerState<PrufaniStartupGate> {
  int _completed = 0;
  bool _ready = false;
  bool _running = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _running) return;
    setState(() {
      _running = true;
      _error = null;
      _completed = 0;
    });
    final bootstrap = PrufaniBootstrap(
      readLocalSession: () async {
        // Trigger secure storage initialization but NEVER delete an old token.
        await ref.read(sessionStoreProvider).read();
      },
      recoverSession: () async {
        await ref.read(guestSessionManagerProvider).ensureSession();
      },
      verifyIdentity: () async {
        await ref.read(authRepositoryProvider).getPlayerId();
      },
      loadHomeData: () async {
        // Warming the very provider that the home screen consumes avoids
        // fetching the same wallet and catalog again after navigation.
        await ref.read(homeOverviewProvider.future);
      },
    );
    try {
      await bootstrap.run(onStageDone: (count) {
        if (mounted) setState(() => _completed = count);
      });
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      _running = false;
    }
  }

  void _retry() {
    // Reload network-dependent provider; the guest session remains intact.
    ref.invalidate(homeOverviewProvider);
    _load();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _ready
            ? const PrufaniHomeScreen(key: ValueKey('prufani_home'))
            : PrufaniLoadingScreen(
                key: const ValueKey('prufani_loading'),
                completedStages: _completed,
                error: _error?.toString(),
                onRetry: _error == null ? null : _retry,
              ),
      );
}

class PrufaniLoadingScreen extends StatefulWidget {
  const PrufaniLoadingScreen({
    super.key,
    required this.completedStages,
    this.error,
    this.onRetry,
  });

  final int completedStages;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<PrufaniLoadingScreen> createState() => _PrufaniLoadingScreenState();
}

class _PrufaniLoadingScreenState extends State<PrufaniLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathing;
  bool _logoVisible = false;

  static const _messages = <String>[
    'Проверяем сохранённые данные',
    'Восстанавливаем гостевую сессию',
    'Получаем данные игрока',
    'Загружаем ресурсы и уровни',
    'Всё готово!',
  ];

  static const _tips = <String>[
    'Одинаковые числа обозначают одинаковые буквы.',
    'Каждую клетку нужно заполнить самостоятельно.',
    'Три ошибки стоят одной жизни.',
    'Жизни постепенно восстанавливаются.',
  ];

  @override
  void initState() {
    super.initState();
    _breathing = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _logoVisible = true);
    });
  }

  @override
  void dispose() {
    _breathing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complete = math.max(0, math.min(
        widget.completedStages, PrufaniBootstrap.totalStages));
    final message = _messages[complete];
    final tip = _tips[math.min(complete, _tips.length - 1)];
    final isError = widget.error != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF6635A5),
        body: Stack(fit: StackFit.expand, children: [
          Image.asset(PrufaniAssets.loadingBackground,
              fit: BoxFit.cover),
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x102C1258), Color(0x0A602E90), Color(0x551C104F)],
            ),
          )),
          SafeArea(
            child: LayoutBuilder(builder: (context, bounds) {
              final compact = bounds.maxHeight < 620;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(children: [
                  AnimatedOpacity(
                    opacity: _logoVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    child: Image.asset(PrufaniAssets.logo,
                      height: compact ? 102 : 137,
                      width: double.infinity,
                      fit: BoxFit.contain),
                  ),
                  SizedBox(height: compact ? 3 : 9),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _breathing,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0,
                              math.sin(_breathing.value * math.pi * 2) * 3),
                          child: child,
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          Image.asset(PrufaniAssets.readingMascot,
                            height: compact ? 230 : 330,
                            width: double.infinity,
                            fit: BoxFit.contain),
                          Positioned(
                            top: 0,
                            right: 6,
                            child: AnimatedBuilder(
                              animation: _breathing,
                              builder: (context, child) => Opacity(
                                opacity: 0.28 +
                                    (0.30 * (0.5 + 0.5 * math.sin(
                                      _breathing.value * math.pi * 2))),
                                child: child,
                              ),
                              child: SvgPicture.asset(
                                PrufaniAssets.loadingSparkles,
                                width: 58, height: 54),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  if (isError) ...[
                    const Text('Нет соединения',
                      style: TextStyle(color: Colors.white,
                        fontSize: 23, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(widget.error!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 12.5, height: 1.35)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: widget.onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: PrufaniColors.yellow,
                        foregroundColor: PrufaniColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 23, vertical: 12),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Повторить'),
                    ),
                  ] else ...[
                    const Text('Загрузка...',
                      style: TextStyle(color: Colors.white,
                        fontSize: 23, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _RealStageProgress(completedStages: complete),
                    const SizedBox(height: 7),
                    Text(message,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFF6ECFF),
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 17),
                  PrufaniLoadingTip(tip: tip),
                ]),
              );
            }),
          ),
        ]),
      ),
    );
  }
}

class _RealStageProgress extends StatelessWidget {
  const _RealStageProgress({required this.completedStages});

  final int completedStages;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Завершено этапов: $completedStages из ${PrufaniBootstrap.totalStages}',
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0,
              end: completedStages / PrufaniBootstrap.totalStages),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, value, _) => Container(
            height: 17,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF452275),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAD6FF)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * value.clamp(0.0, 1.0).toDouble(),
                    height: constraints.maxHeight,
                    child: const ColoredBox(color: PrufaniColors.yellow),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class PrufaniLoadingTip extends StatelessWidget {
  const PrufaniLoadingTip({super.key, required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D8),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x33511F80),
        blurRadius: 12, offset: Offset(0, 6))],
    ),
    child: Row(children: [
      Image.asset(PrufaniAssets.bulb, width: 39, height: 39,
        fit: BoxFit.contain),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Совет для разгадки',
            style: TextStyle(color: PrufaniColors.primaryDark,
              fontSize: 13.5, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(tip, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: PrufaniColors.primaryDark,
              fontSize: 11.5, height: 1.3)),
        ],
      )),
    ]),
  );
}
