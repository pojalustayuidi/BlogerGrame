import 'package:flutter/material.dart';

import '../../../core/theme/prufani_theme.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';

const catalogCardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x19633B9E), blurRadius: 14, offset: Offset(0, 4)),
];

String categoryIllustration(String slug) => switch (slug) {
      'bloggers' => PrufaniAssets.bloggers,
      'tiktokers' => PrufaniAssets.tiktokers,
      _ => PrufaniAssets.streamers,
    };

Color categorySurface(String slug) => switch (slug) {
      'bloggers' => PrufaniColors.blogger,
      'tiktokers' => PrufaniColors.tiktoker,
      _ => PrufaniColors.streamer,
    };

class PrufaniCatalogProgress extends StatelessWidget {
  const PrufaniCatalogProgress({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const Text(
        'Пока нет уровней',
        style: TextStyle(color: PrufaniColors.primaryDark, fontSize: 13),
      );
    }
    final fraction = (completed / total).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$completed из $total пройдено',
          style: const TextStyle(
            color: PrufaniColors.primaryDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: fraction, end: fraction),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: PrufaniColors.primaryDark,
                backgroundColor: const Color(0x245536BA),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PrufaniCategoryCard extends StatelessWidget {
  const PrufaniCategoryCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final PrufaniCategoryProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final category = progress.category;
    final completed = progress.completed;
    final total = progress.total;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(22);
    final summary =
        progress.isEmpty ? 'пока нет уровней' : '$completed из $total пройдено';

    return Semantics(
      label: '${category.title}, $summary',
      button: enabled,
      enabled: enabled,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: categorySurface(category.slug),
            borderRadius: radius,
            border: Border.all(color: const Color(0xCBFFFFFF), width: 1.4),
            boxShadow: catalogCardShadow,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xBFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      categoryIllustration(category.slug),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: const TextStyle(
                            color: PrufaniColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        PrufaniCatalogProgress(
                          completed: completed,
                          total: total,
                        ),
                      ],
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PrufaniColors.primaryDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum PrufaniLevelTileStatus {
  completed('пройден', Icons.check_circle_rounded),
  locked('закрыт', Icons.lock_rounded),
  ready('доступен', Icons.play_arrow_rounded),
  resume('есть сохранённая попытка', Icons.play_arrow_rounded),
  noLives('нет жизней', Icons.favorite_border_rounded),
  unavailable('старт недоступен', null);

  const PrufaniLevelTileStatus(this.label, this.icon);

  final String label;
  final IconData? icon;
}

class PrufaniLevelTile extends StatelessWidget {
  const PrufaniLevelTile({
    super.key,
    required this.level,
    required this.status,
    required this.onTap,
  });

  final LevelSummary level;
  final PrufaniLevelTileStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = status == PrufaniLevelTileStatus.ready ||
        status == PrufaniLevelTileStatus.resume;
    final (surface, ink) = switch (status) {
      PrufaniLevelTileStatus.completed => (
          const Color(0xFFE6F5EB),
          const Color(0xFF206744),
        ),
      PrufaniLevelTileStatus.ready || PrufaniLevelTileStatus.resume => (
          PrufaniColors.lavender,
          PrufaniColors.primaryDark,
        ),
      _ => (const Color(0xFFF0EAF3), const Color(0xFF65576F)),
    };
    final radius = BorderRadius.circular(15);
    final icon = status.icon;

    return Semantics(
      label: 'Уровень ${level.number}, ${status.label}',
      button: onTap != null,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: radius,
            border: Border.all(
              color: current ? PrufaniColors.primary : const Color(0xDFFFFFFF),
              width: current ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${level.number}',
                          style: TextStyle(
                            color: ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: icon == null ? null : Icon(icon, size: 16, color: ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
