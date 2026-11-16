import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/backend_providers.dart';
import '../../../core/theme/prufani_theme.dart';
import '../../economy/domain/economy_models.dart';
import '../../game/domain/game_models.dart';
import '../domain/home_overview.dart';
import 'home_providers.dart';
import 'home_widgets.dart';

Future<void> showPrufaniCategories(
    BuildContext context, WidgetRef ref, HomeOverview overview) async {
  await _openSheet(
    context,
    title: 'Категории',
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final category in overview.categories)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _SheetChoice(
            title: category.title,
            description: '${category.levels} уровней',
            icon: categoryAsset(category.slug),
            selected: overview.category?.slug == category.slug,
            onTap: () {
              ref.read(selectedHomeCategoryProvider.notifier).state =
                  category.slug;
              Navigator.of(context).pop();
            },
          ),
        ),
      if (overview.categories.isEmpty)
        const Text('Категории пока недоступны. Проверь импорт уровней.'),
    ]),
  );
}

/// "Играть" opens the real catalog first. Creating a new attempt happens only
/// after an explicit level selection, never during dashboard initialization.
Future<void> showPrufaniLevels(
    BuildContext context, WidgetRef ref, HomeOverview overview) async {
  var busy = false;
  await _openSheet(
    context,
    title: 'Выбрать уровень',
    child: StatefulBuilder(
      builder: (sheetContext, update) =>
          Column(mainAxisSize: MainAxisSize.min, children: [
        if (busy)
          const Padding(
            padding: EdgeInsets.all(6),
            child: LinearProgressIndicator(color: PrufaniColors.primary),
          ),
        for (final level in overview.levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SheetChoice(
              title: 'Уровень ${level.number}',
              description: level.completed
                  ? 'Пройден'
                  : '${level.letters} букв · ${level.difficulty}',
              icon: categoryAsset(overview.category?.slug),
              selected: false,
              onTap: level.completed || busy
                  ? null
                  : () async {
                      update(() => busy = true);
                      try {
                        final attempt = await ref
                            .read(startOrResumeAttemptProvider)(level.id);
                        final playerId = await ref
                            .read(authRepositoryProvider)
                            .getPlayerId();
                        await ref
                            .read(homeAttemptStoreProvider)
                            .save(playerId, attempt);
                        ref.invalidate(homeOverviewProvider);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await showPrufaniAttempt(context, attempt);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Не удалось открыть уровень: $error'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      } finally {
                        if (sheetContext.mounted) update(() => busy = false);
                      }
                    },
            ),
          ),
        if (overview.levels.isEmpty)
          const Text('В этой категории пока нет уровней.'),
      ]),
    ),
  );
}

/// Resume the exact stored attempt id, validated by the backend.
Future<void> showPrufaniResume(
    BuildContext context, WidgetRef ref, HomeOverview overview) async {
  final saved = overview.activeAttempt;
  if (saved == null) return;
  try {
    final attempt = await ref.read(gameRepositoryProvider).getAttempt(saved.id);
    if (!context.mounted) return;
    await showPrufaniAttempt(context, attempt);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Не удалось восстановить попытку: $error'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

/// Integration hand-off: shows the *actual* persisted layout read-only.
/// The new keyboard/GameNotifier will be implemented in the game UI patch;
/// forwarding to the old whole-phrase-check screen would be incorrect.
Future<void> showPrufaniAttempt(
    BuildContext context, PuzzleAttempt attempt) async {
  await _openSheet(
    context,
    title: 'Уровень ${attempt.levelNumber}',
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Статус: ${attempt.status} · Ошибки: ${attempt.mistakes}',
          style: const TextStyle(
              color: PrufaniColors.primaryDark, fontWeight: FontWeight.w700)),
      const SizedBox(height: 13),
      Wrap(spacing: 4, runSpacing: 5, children: [
        for (final cell in attempt.layout)
          if (cell.isLetter)
            Container(
              width: 34,
              height: 50,
              decoration: BoxDecoration(
                color: cell.isFilled
                    ? const Color(0xFFDAF8EC)
                    : const Color(0xFFF1E8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD9C9F4)),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cell.given ?? cell.letter ?? '·',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: PrufaniColors.ink)),
                    Text('${cell.number ?? ''}',
                        style: const TextStyle(
                            fontSize: 9, color: PrufaniColors.primaryDark)),
                  ]),
            )
          else
            SizedBox(
                width: 14,
                height: 50,
                child: Center(
                    child: Text(cell.separator ?? ' ',
                        style: const TextStyle(color: PrufaniColors.ink)))),
      ]),
      const SizedBox(height: 16),
      const Text(
          'Это сохранённая сервером криптограмма. '
          'Полноценную клавиатуру подключим отдельным этапом.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: PrufaniColors.muted)),
    ]),
  );
}

Future<void> showPrufaniShop(BuildContext context, WidgetRef ref) async {
  final offersFuture = ref.read(economyRepositoryProvider).shopOffers();
  await _openSheet(
    context,
    title: 'Магазин',
    child: FutureBuilder<List<ShopOffer>>(
      future: offersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Не удалось загрузить предложения магазина.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: PrufaniColors.primary),
          );
        }
        final offers = snapshot.data!;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Предложения получены с сервера. Покупки добавим '
              'при разработке полного экрана магазина.',
              style: TextStyle(color: PrufaniColors.muted, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final offer in offers.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SheetChoice(
                icon: offer.kind.toLowerCase().contains('life')
                    ? PrufaniAssets.heart
                    : PrufaniAssets.bulb,
                title: '${_offerTitle(offer.kind)} ×${offer.quantity}',
                description: '${offer.costCoins} монет',
                selected: false,
                onTap: null, // prices visible, purchase not implemented yet
              ),
            ),
          if (offers.isEmpty) const Text('Предложений пока нет.'),
        ]);
      },
    ),
  );
}

String _offerTitle(String kind) {
  final value = kind.toLowerCase();
  if (value.contains('life')) return 'Жизни';
  if (value.contains('hint')) return 'Подсказки';
  return 'Набор';
}

Future<void> showPrufaniProfile(BuildContext context, WidgetRef ref) async {
  final idFuture = ref.read(authRepositoryProvider).getPlayerId();
  await _openSheet(
    context,
    title: 'Профиль',
    child: FutureBuilder<String>(
      future: idFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Не удалось получить профиль гостя.');
        }
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: PrufaniColors.primary);
        }
        final playerId = snapshot.data!;
        return Column(children: [
          const Icon(Icons.account_circle_rounded,
              color: PrufaniColors.primary, size: 66),
          const SizedBox(height: 10),
          const Text('Гостевой аккаунт',
              style: TextStyle(
                  fontSize: 18,
                  color: PrufaniColors.ink,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          SelectableText(playerId,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PrufaniColors.muted, fontSize: 11)),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Скопировать ID'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: playerId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID скопирован')),
              );
            },
          ),
        ]);
      },
    ),
  );
}

Future<void> showPrufaniSettings(BuildContext context) async => _openSheet(
      context,
      title: 'Настройки',
      child: const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.tune_rounded, color: PrufaniColors.primary, size: 60),
        SizedBox(height: 12),
        Text(
            'Параметры звука, языка и уведомлений '
            'сделаем в отдельном экране настроек.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PrufaniColors.muted)),
        SizedBox(height: 12),
        Text('ПРУФАНИ! · UI v1',
            style: TextStyle(fontSize: 12, color: PrufaniColors.primaryDark)),
      ]),
    );

Future<void> showPrufaniLives(BuildContext context, GameWallet wallet) async =>
    _openSheet(
      context,
      title: 'Жизни',
      child: Column(children: [
        Image.asset(PrufaniAssets.heart, height: 60),
        const SizedBox(height: 8),
        Text('${wallet.lives}/${wallet.maxLives}',
            style: const TextStyle(
                color: PrufaniColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Восстановление: каждые ${wallet.lifeRegenMinutes} минут.',
            style: const TextStyle(color: PrufaniColors.muted)),
        const SizedBox(height: 6),
        const Text('Точное время следующей жизни — в верхней панели.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PrufaniColors.muted, fontSize: 12)),
      ]),
    );

Future<void> showPrufaniRewards(BuildContext context) async => _openSheet(
      context,
      title: 'Больше наград!',
      child: Column(children: [
        Image.asset(PrufaniAssets.coins, height: 69),
        const SizedBox(height: 10),
        const Text('Проходи уровни и получай награды от сервера.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PrufaniColors.ink, fontSize: 14)),
        const SizedBox(height: 7),
        const Text(
            'Количество монет определяет backend, '
            'а не оформление главного экрана.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PrufaniColors.muted, fontSize: 12)),
      ]),
    );

Future<void> _openSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: PrufaniColors.cream,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 19,
          right: 19,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          top: 2,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: PrufaniColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 23)),
              const SizedBox(height: 17),
              child,
            ]),
          ),
        ),
      ),
    );

class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final String icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFE4D5FF) : PrufaniColors.lavender,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selected ? PrufaniColors.primary : Colors.white,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Image.asset(icon, width: 44, height: 44, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            color: PrufaniColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                    Text(description,
                        style: const TextStyle(
                            color: PrufaniColors.muted, fontSize: 12)),
                  ])),
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: PrufaniColors.primaryDark),
            ]),
          ),
        ),
      );
}
