import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/prufani_theme.dart';
import '../../economy/domain/economy_models.dart';
import '../domain/home_overview.dart';

const _cardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x1D6C47A3), blurRadius: 12, offset: Offset(0, 5)),
];

class HomeBrandHeader extends StatelessWidget {
  const HomeBrandHeader({super.key, required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 84,
        child: Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                PrufaniAssets.logo,
                width: 285,
                height: 81,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: 'Настройки',
            button: true,
            child: Material(
              color: const Color(0xFFF6ECFF),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFE2D2F7)),
                  ),
                  child: SvgPicture.asset(
                    PrufaniAssets.settings,
                    colorFilter: const ColorFilter.mode(
                        PrufaniColors.primaryDark, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// Refreshes only the resource strip, not the entire dashboard, once per second.
class ResourceStrip extends StatefulWidget {
  const ResourceStrip({
    super.key,
    required this.wallet,
    required this.onCoins,
    required this.onLives,
    required this.onHints,
    this.onRegenDue,
  });

  final GameWallet wallet;
  final VoidCallback onCoins;
  final VoidCallback onLives;
  final VoidCallback onHints;
  final VoidCallback? onRegenDue;

  @override
  State<ResourceStrip> createState() => _ResourceStripState();
}

class _ResourceStripState extends State<ResourceStrip> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  DateTime? _notifiedDeadline;

  @override
  void initState() {
    super.initState();
    _startClockIfNeeded();
  }

  @override
  void didUpdateWidget(ResourceStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallet.nextLifeAt != oldWidget.wallet.nextLifeAt ||
        widget.wallet.lives != oldWidget.wallet.lives) {
      _clock?.cancel();
      _clock = null;
      _notifiedDeadline = null;
      _now = DateTime.now();
      _startClockIfNeeded();
    }
  }

  void _startClockIfNeeded() {
    if (widget.wallet.lives >= widget.wallet.maxLives ||
        widget.wallet.nextLifeAt == null) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      final deadline = widget.wallet.nextLifeAt!;
      if (!_now.isBefore(deadline) && _notifiedDeadline != deadline) {
        _notifiedDeadline = deadline;
        widget.onRegenDue?.call();
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: PrufaniResourceCard(
            icon: PrufaniAssets.coins,
            value: formatCoins(widget.wallet.coins),
            background: const Color(0xFFFFF2D7),
            onTap: widget.onCoins,
            showPlus: true,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: PrufaniResourceCard(
            icon: PrufaniAssets.heart,
            value: '${widget.wallet.lives}/${widget.wallet.maxLives}',
            caption: widget.wallet.lives < widget.wallet.maxLives
                ? lifeCountdown(widget.wallet, _now)
                : null,
            background: const Color(0xFFFFE8F1),
            onTap: widget.onLives,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: PrufaniResourceCard(
            icon: PrufaniAssets.bulb,
            value: '${widget.wallet.hints}',
            background: const Color(0xFFF0E7FF),
            onTap: widget.onHints,
            showPlus: true,
          ),
        ),
      ]);
}

String formatCoins(int value) {
  final raw = value.toString();
  final digits = raw.startsWith('-') ? raw.substring(1) : raw;
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return raw.startsWith('-') ? '-$grouped' : grouped;
}

String lifeCountdown(GameWallet wallet, DateTime now) {
  if (wallet.lives >= wallet.maxLives) return '';
  final deadline = wallet.nextLifeAt;
  if (deadline == null) return 'Ожидание';
  final remaining = deadline.difference(now);
  if (remaining.inSeconds <= 0) return 'Обновление...';
  final seconds = remaining.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = seconds % 60;
  if (hours > 0) return 'через $hours:${minutes.toString().padLeft(2, '0')}';
  return 'через $minutes:${rest.toString().padLeft(2, '0')}';
}

class PrufaniResourceCard extends StatelessWidget {
  const PrufaniResourceCard({
    super.key,
    required this.icon,
    required this.value,
    required this.background,
    required this.onTap,
    this.caption,
    this.showPlus = false,
  });

  final String icon;
  final String value;
  final String? caption;
  final Color background;
  final VoidCallback onTap;
  final bool showPlus;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            height: 56, // previous home was 67 dp; 16% more compact
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFE7D9F2)),
              boxShadow: _cardShadow,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(children: [
              Image.asset(icon, width: 29, height: 29, fit: BoxFit.contain),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            value,
                            key: ValueKey(value),
                            maxLines: 1,
                            style: const TextStyle(
                              color: PrufaniColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (caption != null && caption!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(caption!,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: PrufaniColors.primaryDark)),
                        ),
                      ),
                  ],
                ),
              ),
              if (showPlus) ...[
                const SizedBox(width: 2),
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: background == const Color(0xFFFFF2D7)
                        ? PrufaniColors.yellow
                        : const Color(0xFFD5BCFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 17,
                      color: PrufaniColors.ink),
                ),
              ],
            ]),
          ),
        ),
      );
}

class PrufaniPrimaryButton extends StatefulWidget {
  const PrufaniPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<PrufaniPrimaryButton> createState() => _PrufaniPrimaryButtonState();
}

class _PrufaniPrimaryButtonState extends State<PrufaniPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        child: Material(
          color: widget.onPressed == null
              ? const Color(0xFFE0D9D6)
              : PrufaniColors.yellow,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onHighlightChanged: (pressed) {
              if (mounted) setState(() => _pressed = pressed);
            },
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(17),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(widget.label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: PrufaniColors.ink,
                          )),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 19, color: PrufaniColors.ink),
                ]),
              ),
            ),
          ),
        ),
      );
}

class PrufaniProgressCard extends StatelessWidget {
  const PrufaniProgressCard({
    super.key,
    required this.overview,
    required this.onPrimaryAction,
  });

  final HomeOverview overview;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final hasLevels = overview.totalCount > 0;
    final number = overview.displayedLevelNumber;
    final title = overview.categoryFinished
        ? 'Всё пройдено!'
        : number == null
            ? 'Нет уровней'
            : 'Уровень $number';
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9360EF), Color(0xFF7042D5)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(
            color: Color(0x35734BC2), blurRadius: 15, offset: Offset(0, 7))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 3, 4, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ТЕКУЩИЙ УРОВЕНЬ',
                      style: TextStyle(fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFECE4FF))),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title,
                        style: const TextStyle(fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
            Image.asset(PrufaniAssets.clapper,
                width: 56, height: 55, fit: BoxFit.contain),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EDFF),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(children: [
            Row(children: [
              Image.asset(categoryAsset(overview.category?.slug),
                  width: 40, height: 40, fit: BoxFit.contain),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(overview.category?.title ?? 'Категория недоступна',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15,
                            color: PrufaniColors.ink,
                            fontWeight: FontWeight.w900)),
                    Text('${overview.completedCount} из ${overview.totalCount} пройдено',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11,
                            color: PrufaniColors.muted)),
                  ],
                ),
              ),
              Text('${overview.progressPercent}%',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: PrufaniColors.primaryDark)),
            ]),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: overview.completionFraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0).toDouble(),
                  minHeight: 9,
                  backgroundColor: const Color(0xFFD7C5F9),
                  color: PrufaniColors.yellow,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrufaniPrimaryButton(
                label: overview.primaryActionLabel,
                onPressed: hasLevels && !overview.categoryFinished
                    ? onPrimaryAction
                    : null,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Kept as a compatibility name for older imports in this codebase.
class ProgressHeroCard extends StatelessWidget {
  const ProgressHeroCard({super.key, required this.overview,
    required this.onContinue});
  final HomeOverview overview;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) => PrufaniProgressCard(
    overview: overview, onPrimaryAction: onContinue);
}

String categoryAsset(String? slug) {
  switch (slug) {
    case 'bloggers': return PrufaniAssets.bloggers;
    case 'tiktokers': return PrufaniAssets.tiktokers;
    default: return PrufaniAssets.streamers;
  }
}

class HomeFeatureCards extends StatelessWidget {
  const HomeFeatureCards({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _FeatureCard(
          icon: PrufaniAssets.daily,
          title: 'Загадка дня',
          description: 'Новая цитата каждый день',
          color: const Color(0xFFFFF2D7),
        )),
        const SizedBox(width: 8),
        Expanded(child: _FeatureCard(
          icon: PrufaniAssets.case404,
          title: 'Дело 404',
          description: 'Особая загадка',
          color: const Color(0xFFEEE6FF),
          badge: 'Скоро',
        )),
      ]);
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title,
    required this.description, required this.color, this.badge});

  final String icon;
  final String title;
  final String description;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$title — скоро',
        enabled: false,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _cardShadow,
          ),
          child: Row(children: [
            Image.asset(icon, width: 42, height: 46, fit: BoxFit.contain),
            const SizedBox(width: 6),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: PrufaniColors.ink)),
                ),
                const SizedBox(height: 2),
                Text(description, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5,
                        height: 1.15, color: PrufaniColors.ink)),
                if (badge != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFD5BEFF),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(badge!, style: const TextStyle(
                        color: PrufaniColors.primaryDark,
                        fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            )),
          ]),
        ),
      );
}

class HomeRewardBanner extends StatelessWidget {
  const HomeRewardBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF8961D7),
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              boxShadow: _cardShadow,
            ),
            child: Row(children: [
              Image.asset(PrufaniAssets.crown,
                  width: 49, height: 49, fit: BoxFit.contain),
              const SizedBox(width: 5),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Больше наград!',
                      style: TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w900)),
                  Text('Проходи уровни и получай монеты',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white,
                          fontSize: 10.5)),
                ],
              )),
              Image.asset(PrufaniAssets.coins,
                  width: 39, height: 42, fit: BoxFit.contain),
            ]),
          ),
        ),
      );
}

enum HomeTab { home, categories, shop, profile }

class PrufaniBottomNavigation extends StatelessWidget {
  const PrufaniBottomNavigation({super.key, required this.onSelect});
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (HomeTab.home, 'Главная', PrufaniAssets.home),
      (HomeTab.categories, 'Категории', PrufaniAssets.categories),
      (HomeTab.shop, 'Магазин', PrufaniAssets.shop),
      (HomeTab.profile, 'Профиль', PrufaniAssets.profile),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEFF),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE2D2F7)),
        boxShadow: _cardShadow,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        for (final (tab, label, icon) in tabs)
          Expanded(child: Material(
            color: tab == HomeTab.home
                ? PrufaniColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              onTap: () => onSelect(tab),
              borderRadius: BorderRadius.circular(19),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Column(mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    SvgPicture.asset(icon, width: 20, height: 20,
                      colorFilter: ColorFilter.mode(
                          tab == HomeTab.home
                              ? Colors.white : PrufaniColors.primaryDark,
                          BlendMode.srcIn)),
                    const SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown,
                      child: Text(label,
                        style: TextStyle(fontSize: 10.5,
                            color: tab == HomeTab.home
                                ? Colors.white : PrufaniColors.ink,
                            fontWeight: FontWeight.w800))),
                  ]),
              ),
            ),
          )),
      ]),
    );
  }
}

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({super.key, required this.onSelect});
  final ValueChanged<HomeTab> onSelect;
  @override
  Widget build(BuildContext context) => PrufaniBottomNavigation(onSelect: onSelect);
}

class HomeLoadingPanel extends StatelessWidget {
  const HomeLoadingPanel({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 175,
    decoration: BoxDecoration(
      color: PrufaniColors.lavender,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Center(child: CircularProgressIndicator(
        color: PrufaniColors.primary)),
  );
}

class HomeErrorPanel extends StatelessWidget {
  const HomeErrorPanel({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: PrufaniColors.lavender,
      borderRadius: BorderRadius.circular(22)),
    child: Column(children: [
      const Icon(Icons.wifi_off_rounded, size: 38,
          color: PrufaniColors.primaryDark),
      const SizedBox(height: 8),
      const Text('Не удалось загрузить меню', textAlign: TextAlign.center,
          style: TextStyle(color: PrufaniColors.ink,
              fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Проверь соединение и попробуй снова.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PrufaniColors.muted, fontSize: 12)),
      const SizedBox(height: 12),
      PrufaniPrimaryButton(label: 'Повторить', onPressed: onRetry),
    ]),
  );
}

double clampHomePadding(double width) =>
    math.min(18.0, math.max(9.0, width * .043));
