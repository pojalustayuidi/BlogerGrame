# ПРУФАНИ! — Flutter UI Patch 03 (Главный экран)

Этот ZIP устанавливается **поверх актуального main**, в котором слит PR #2 (Clean Architecture). Не заменяйте всю папку проекта.

## 1. Подготовка и отдельная ветка

```powershell
cd D:\Bloger\BlogerGrame
git status
git switch main
git pull --ff-only
git switch -c feat/flutter-03-prufani-home-ui
```

Если у вас остались незакоммиченные изменения, сначала решите, что с ними делать. Не применяйте `git reset --hard`.

## 2. Установка патча

Распакуйте ZIP **в корень** `D:\Bloger\BlogerGrame` так, чтобы файлы оказались напрямую в `lib/`, `assets/` и `test/`, а не внутри дополнительной папки `Prufani_...`.

Пример, если ZIP лежит в `Downloads`:

```powershell
Expand-Archive -Path "$env:USERPROFILE\Downloads\Prufani_Flutter_Home_Patch_03.zip" -DestinationPath "D:\Bloger\BlogerGrame" -Force
```

Изменения:
- новый `lib/main.dart` запускает `PrufaniHomeScreen` вместо старого `LoadingScreen`;
- `lib/core/theme/prufani_theme.dart` содержит токены и пути ассетов;
- `lib/features/home/domain/home_overview.dart` — вычисляемый прогресс по серверным уровням;
- `lib/features/home/presentation/` — Riverpod provider, экран, виджеты, bottom sheets;
- `assets/prufani/` — полный пользовательский Asset Kit v1.1 (PNG/SVG);
- `pubspec.yaml` расширен только регистрацией nested assets, зависимости не менялись;
- `test/home_overview_test.dart` — тесты подсчёта прогресса, пустых каталогов и таймера.

## 3. Форматирование, тесты и диагностика

```powershell
cd D:\Bloger\BlogerGrame
flutter pub get
dart format lib\main.dart lib\core\theme\prufani_theme.dart lib\features\home test\home_overview_test.dart
flutter test test\home_overview_test.dart
flutter test
flutter analyze
```

В `flutter analyze` пока могут отображаться 81 старое замечание из legacy UI. **Новые ошибки компиляции появляться не должны.** Если появились — сохраните вывод; не делайте коммит, пока не исправим.

## 4. Проверка на физическом телефоне

Backend должен быть запущен на локальном ПК: `http://127.0.0.1:8085`. Для 42 черновых уровней в backend `.env` нужен `LOCAL_DRAFT_PREVIEW=1` (на локальной машине).

```powershell
Invoke-RestMethod http://127.0.0.1:8085/health
& "D:\Android\Sdk\platform-tools\adb.exe" reverse tcp:8085 tcp:8085
flutter run -d R5CY5453DEY --debug --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

Обратите внимание: **без** `-t lib/main_api_smoke.dart`: теперь проверяем **основной запуск** `lib/main.dart`.

Примеры проверок:
- отображается оригинальный логотип «ПРУФАНИ!» и три ресурсные карточки;
- баланс, жизни, подсказки взяты из backend, не зашиты в дизайн;
- отображается категория и процент реального прохождения (у нового игрока обычно 0%, а не 40% из концепта);
- «Категории» открывает список из backend, переключение меняет активную категорию;
- «Магазин» открывает реальные предложения в режиме просмотра (покупки ещё не реализованы);
- «Профиль» показывает актуальный гостевой ID;
- «Продолжить» пока показывает описание следующего уровня: игровой экран подключим отдельным патчем;
- «Загадка дня» и «Дело 404» честно отмечены как будущие функции;
- работают pull-to-refresh и повторная загрузка при ошибках сети.

Старое меню, провайдеры и старый экран игры **намеренно не удалены**, хотя теперь не участвуют в стартовом маршруте. Их будем убирать после миграции всей игры.

## 5. Коммит и PR

```powershell
git status
git add -A
git diff --cached --check
git diff --cached --stat
git commit -m "feat(flutter): build prufani home screen with server-backed progress"
git push -u origin feat/flutter-03-prufani-home-ui
```

После успешного push создайте PR в `main`, протестируйте сборку и слейте.

## Ограничения этапа

Это **UI-патч главного экрана**, а не завершённый игровой flow. В целях безопасности не подключается старая механика, которая могла бы списывать жизни не через новый backend. Контракт `GameNotifier` и переход на экран криптограммы сделаем следующим этапом.

В среде подготовки архива Flutter SDK не установлен, поэтому фактическую компиляцию и widget-тесты необходимо выполнить локально.
