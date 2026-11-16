# ПРУФАНИ! — UI Polish 01 / Windows 11

## Состав патча

Полные Dart-файлы для существующих `lib/features/home/`, заменённый старый
`lib/screens/loading_screen/loading_screen.dart`, новый независимый Bootstrap,
`lib/main.dart`, путь к новым ассетам в `pubspec.yaml`, тесты, полный единый
`assets/prufani/` из предоставленного `Prufani_Complete_UI_Kit_v1_2`.

- Никаких изменений backend, миграций, старых игровых сервисов, токенов или Android Gradle.
- Никаких новых dependencies: используются существующие Riverpod,
  shared_preferences, flutter_secure_storage, Dio, flutter_svg.
- Патч совместим с Flutter-репозиторием после Clean Architecture (#2),
  также включает необходимые файлы Home Patch 03, который может быть только
  в локальной ветке и не находится на `main` GitHub.

## Установка (не теряем незакоммиченные изменения)

1. На ПК открой PowerShell:

```powershell
cd D:\Bloger\BlogerGrame
git status
git branch --show-current
```

2. Не переключайся на `main`, если твой рабочий Home Patch 03 ещё не закоммичен.
   Сначала сохрани свою текущую работу в Git или резервной копии. Создай
   отдельную ветку **от той ветки, где сейчас работает меню**:

```powershell
git switch -c feat/flutter-ui-polish-01-loading-home
```

3. Скачай ZIP и распакуй прямо в корень Flutter-проекта, сохраняя пути:

```powershell
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\Prufani_UI_Polish_01.zip" `
  -DestinationPath "D:\Bloger\BlogerGrame" -Force
```

Если архив скачался в другое место, замени только параметр `-LiteralPath`.
Существующая папка `assets/prufani/` будет обновлена той же структурой v1.2,
без создания второй копии. `SharedPreferences` и Secure Storage не удаляются.

4. Приведи код к форматированию и запусти проверки:

```powershell
flutter pub get
dart format lib/main.dart lib/core/theme/prufani_theme.dart `
  lib/features/home lib/screens/loading_screen test/home_overview_test.dart `
  test/startup_bootstrap_test.dart test/home_attempt_store_test.dart `
  test/home_polish_widget_test.dart
flutter analyze
flutter test
```

В проекте до патча были замечания `withOpacity`, `avoid_print` и два предупреждения
об unused-коде в старых экранах. Важно отсутствие новых **error**, а не
абсолютно нулевое количество старых сообщений анализатора.

5. Запусти backend в отдельном PowerShell (согласно его README), проверь:

```powershell
Invoke-RestMethod http://127.0.0.1:8085/health
& "D:\Android\Sdk\platform-tools\adb.exe" reverse tcp:8085 tcp:8085
& "D:\Android\Sdk\platform-tools\adb.exe" reverse --list
```

6. Запусти обычный Flutter entrypoint (НЕ main_api_smoke.dart):

```powershell
flutter run -d R5CY5453DEY --debug `
  --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

`LOCAL_DRAFT_PREVIEW=1` в `.env` backend нужен только для локальных
неопубликованных уровней. Изменять backend ради этого UI патча не требуется.

## Проверка и коммит

После ручной проверки на Samsung:

```powershell
git status
git diff --check
git add lib/main.dart lib/core/theme/prufani_theme.dart `
  lib/features/home lib/screens/loading_screen assets/prufani `
  pubspec.yaml test/home_overview_test.dart test/startup_bootstrap_test.dart `
  test/home_attempt_store_test.dart test/home_polish_widget_test.dart `
  INSTALL_WINDOWS_11.md CHANGELOG_UI_POLISH_01.md QA_UI_POLISH_01.md
git diff --cached --stat
git diff --cached --check
git commit -m "feat(flutter): polish startup and home using Prufani UI kit"
git push -u origin feat/flutter-ui-polish-01-loading-home
```

Если какие-либо файлы Git пока не видит, проверь `git status`.
Не делай `git add -A` без просмотра — рядом могут находиться временные логи.

## Ограничения API/игрового экрана

- `GET /api/v1/game/levels` отдаёт `completed`, но **не** `activeAttemptId`.
  Поэтому кнопка «Продолжить» доступна только для известной этому устройству
  серверной попытки. Её UUID хранится в SharedPreferences **по ID гостя**;
  при запуске проверяется через `GET /api/v1/game/attempts/:id`.
- Если попытка создана на другом устройстве или в старом диагностическом экране,
  этот endpoint не даёт её найти. **Не изображаем её существование**.
- «Играть» открывает настоящие уровни. Только после выбора конкретного уровня
  создаётся/восстанавливается серверная попытка. На данный момент она
  открывается **read-only**, поскольку интерактивная клавиатура относится
  к следующему этапу Game UI. Сохранение попытки не списывает жизнь.
- Магазин пока показывает реальные предложения без возможности оплаты;
  «Загадка дня» и «Дело 404» отключены.
- Гостевая сессия хранится прежней `GuestSessionManager` с теми же ключами;
  временные сетевые ошибки никогда не удаляют её. При отвергнутом refresh
  токене экран показывает ошибку вместо создания второго пользователя.

## Что в ZIP не входит

Нет сброса базы данных, миграций, новых endpoint'ов, новой версии игры
или замены игровых API. Нет автоматической заливки на GitHub.
