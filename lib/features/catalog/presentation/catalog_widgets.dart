import 'package:flutter/material.dart';

import '../../../core/theme/prufani_theme.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';

/// Styling for the two existing catalog routes. All totals come from /levels.
const catalogCardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x20633B9E), blurRadius: 15, offset: Offset(0, 6)),
];

String categoryIllustration(String slug) {
  switch (slug) {
    case 'bloggers':
      return PrufaniAssets.bloggers;
    case 'tiktokers':
      return PrufaniAssets.tiktokers;
    default:
      return PrufaniAssets.streamers;
  }
}

Color categorySurface(String slug) {
  switch (slug) {
    case 'bloggers':
      return PrufaniColors.blogger;
    case 'tiktokers':
      return PrufaniColors.tiktoker;
    default:
      return PrufaniColors.streamer;
  }
}

String categoryCaption(String slug) {
  switch (slug) {
    case 'bloggers':
      return 'Цитаты из блогов и шоу';
    case 'tiktokers':
      return 'Фразы из коротких видео';
    default:
      return 'Фразы известных стримеров';
  }
}

List<Color> categoryGradient(String slug) {
  switch (slug) {
    case 'bloggers':
      return const [Color(0xFFFFE8A4), Color(0xFFFFC766)];
    case 'tiktokers':
      return const [Color(0xFFFFB9E5), Color(0xFFEF82C8)];
    default:
      return const [Color(0xFFAC6EFF), Color(0xFF7138D5)];
  }
}

/// Bright, illustrated game-pack card. [wide] uses the full row for the third
/// real category; it does NOT invent a fourth "Mix" API category.
class PrufaniCategoryCard extends StatelessWidget {
  const PrufaniCategoryCard({
    super.key,
    required this.progress,
    required this.onTap,
    this.wide = false,
  });

  final PrufaniCategoryProgress progress;
  final VoidCallback? onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final category = progress.category;
    final dark = category.slug == 'streamers';
    final foreground = dark ? Colors.white : PrufaniColors.ink;
    final subtle = dark ? const Color(0xFFF0E3FF) : PrufaniColors.primaryDark;
    return SizedBox(
      height: wide ? 155 : 207,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: categoryGradient(category.slug),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xCBFFFFFF), width: 1.4),
            boxShadow: catalogCardShadow,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final imageSide = wide ? 115.0 : (width * .55).clamp(70.0, 105.0);
              final leftWidth = wide ? width - 146 : width * .63;
              return Stack(clipBehavior: Clip.hardEdge, children: [
                Positioned(
                  right: -25,
                  top: wide ? -50 : 28,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0x25FFFFFF)),
                  ),
                ),
                Positioned(
                  right: wide ? 10 : 0,
                  top: wide ? 4 : 55,
                  child: Opacity(
                    opacity: .95,
                    child: Image.asset(
                      categoryIllustration(category.slug),
                      width: imageSide,
                      height: imageSide,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 12,
                  width: wide ? width - 142 : width - 26,
                  child: Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: wide ? 23 : 21,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                      shadows: dark
                          ? const [
                              Shadow(color: Color(0x79492291), blurRadius: 7)
                            ]
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: wide ? 50 : 52,
                  width: leftWidth - 13,
                  child: Text(
                    categoryCaption(category.slug),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtle,
                      fontSize: wide ? 12.5 : 11.5,
                      height: 1.24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 9,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .80),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      Image.asset('assets/prufani/icons/resources/star.png',
                          width: 21, height: 21, fit: BoxFit.contain),
                      const SizedBox(width: 3),
                      Text('${progress.completed}/${progress.total}',
                          style: const TextStyle(
                            color: PrufaniColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(width: 7),
                      Expanded(
                          child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress.fraction.clamp(0.0, 1.0).toDouble(),
                          minHeight: 9,
                          backgroundColor: const Color(0xFFCDB4EC),
                          color: const Color(0xFFFFCB28),
                        ),
                      )),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: PrufaniColors.primaryDark, size: 21),
                    ]),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// Pure pagination for the level grid; 20 items exactly match the reference's
/// five columns x four rows on typical Android phones.
const prufaniLevelsPerPage = 20;

int levelPageCount(int total) =>
    total <= 0 ? 1 : (total + prufaniLevelsPerPage - 1) ~/ prufaniLevelsPerPage;

List<LevelSummary> levelsForPage(List<LevelSummary> ordered, int page) {
  final start = page * prufaniLevelsPerPage;
  if (start < 0 || start >= ordered.length) return const [];
  final end = start + prufaniLevelsPerPage > ordered.length
      ? ordered.length
      : start + prufaniLevelsPerPage;
  return ordered.sublist(start, end);
}

/// Stars are a *visual completion motif*, not a claimed server star rating:
/// the API currently only sends completed: true/false.
class PrufaniLevelTile extends StatelessWidget {
  const PrufaniLevelTile({
    super.key,
    required this.level,
    required this.isActive,
    required this.onTap,
    this.isRecommended = false,
  });

  final LevelSummary level;
  final bool isActive;
  final bool isRecommended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final complete = level.completed;
    final current = !complete && (isActive || isRecommended);
    final gradient = complete
        ? const [Color(0xFFAA66FA), Color(0xFF682CCA)]
        : current
            ? const [Color(0xFFFFEF79), Color(0xFFFFBE2C)]
            : const [Color(0xFFFFFBFF), Color(0xFFE9D6FA)];
    final ink = complete ? Colors.white : PrufaniColors.primaryDark;
    return Semantics(
      label:
          'Уровень ${level.number}, ${complete ? 'пройден' : isActive ? 'в процессе' : 'доступен'}',
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        borderRadius: BorderRadius.circular(21),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            border: Border.all(
              width: current ? 2 : 1.2,
              color:
                  current ? const Color(0xFFFFC02D) : const Color(0xC2FFFFFF),
            ),
            boxShadow: catalogCardShadow,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Stack(children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 11, 2, 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                        child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${level.number}',
                          style: TextStyle(
                              fontSize: 29,
                              color: ink,
                              fontWeight: FontWeight.w900)),
                    )),
                    const SizedBox(height: 5),
                    if (current)
                      const Icon(Icons.play_circle_fill_rounded,
                          color: PrufaniColors.primaryDark, size: 24)
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            3,
                            (_) => Icon(
                                  complete
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: complete
                                      ? const Color(0xFFFFD739)
                                      : const Color(0xFFBFA8D3),
                                  size: 15,
                                )),
                      ),
                  ]),
                ),
              ),
              if (complete)
                const Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.check_circle_rounded,
                        size: 22, color: Color(0xFF25BA67))),
              if (isActive && !complete)
                const Positioned(
                    top: 2,
                    right: 4,
                    child: Icon(Icons.bolt_rounded,
                        color: PrufaniColors.primaryDark, size: 17)),
            ]),
          ),
        ),
      ),
    );
  }
}
