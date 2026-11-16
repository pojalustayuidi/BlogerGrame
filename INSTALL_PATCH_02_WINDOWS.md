# BlogerGrame — Patch 02: Clean Architecture (без игрового UI)

База патча: Flutter `main` после PR #1 (`e47823ebd607e587bb9e928317a4728e03378939`). Работаем с новой веткой. Патч **не редактирует главное меню, игровой экран, экран магазина и их текущие провайдеры**.

## Установка на Windows 11

1. Убедитесь, что локальных незакоммиченных изменений нет: `git status`. При наличии изменений сохраните их отдельно.
2. В PowerShell внутри `D:\Bloger\BlogerGrame`:

```powershell
git switch main
git pull --ff-only
git switch -c refactor/flutter-02-clean-architecture
```

3. Распакуйте содержимое ZIP непосредственно в корень проекта `D:\Bloger\BlogerGrame`. Разрешите перезапись **только** `lib/dev/backend_check_screen.dart`, `lib/main_api_smoke.dart` и `test/backend_models_test.dart`. Остальные Dart-файлы должны быть новыми.
4. После копирования, **не до него**, выполните:

```powershell
powershell -ExecutionPolicy Bypass -File .\REMOVE_OBSOLETE_FILES.ps1
flutter pub get
flutter test test/backend_models_test.dart test/game_usecases_test.dart test/backend_client_test.dart
flutter analyze
```

`flutter analyze` может показывать старые замечания из `lib/screens` и `lib/providers`; ошибки компиляции недопустимы. Если появились новые ошибки в `core` или `features`, не коммитьте — пришлите лог.

## Проверка реального Android

В backend включите `APP_ENV=local` и `LOCAL_DRAFT_PREVIEW=1`, запустите PostgreSQL и `npm run dev`. Проверьте `Invoke-RestMethod http://127.0.0.1:8085/health`.

```powershell
& "D:\Android\Sdk\platform-tools\adb.exe" reverse tcp:8085 tcp:8085
& "D:\Android\Sdk\platform-tools\adb.exe" reverse --list
flutter run -d R5CY5453DEY -t lib/main_api_smoke.dart --debug `
  --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

Проверяем: возвращается **тот же UUID гостя** (ключ Secure Storage сохранён); кошелёк по-прежнему показывает серверные ресурсы; категории и уровни из PostgreSQL; открытие незавершённой попытки и повторное открытие не создаёт другую попытку. Для чистого гостя исходно 30 монет, 5 жизней и 2 подсказки; у существующего аккаунта баланс может отличаться.

Обычный `flutter run` с `lib/main.dart` пока запускает **старые игровые экраны**: это ожидаемо. Действующий backend-слой в этих экранах заменим отдельно при разработке UI.

## Git перед коммитом

```powershell
git status
git diff --check
git add -A
git diff --cached --stat
git diff --cached --check
git commit -m "refactor(flutter): extract backend into clean architecture features"
git push -u origin refactor/flutter-02-clean-architecture
```

Перед коммитом проверьте, что в `git diff --cached --stat` **нет изменений игровых экранов и старых провайдеров**, кроме двух диагностических файлов и тестов. `lib/core/backend/`, два старых архива и шаблонный тест должны быть удалены. В репозиторий не должны попасть `.env`, секреты, `build/` и файлы логов.

## Что именно удаляем и почему

- `lib/core/backend/` — его классы перенесены/разделены на core/network + features.
- `lib/lib.zip` и `lib/lib.rar` — архивы из исходников **перемещаются** в соседнюю папку `D:\Bloger\BlogerGrame_legacy_archives` для безопасного сохранения, а из Git удаляются (если архивы с таким именем там ещё не существуют).
- `lib/screens/level_screen/level_widgets/phrase_word.dart` — только если он **по-прежнему пустой** и нет импортов.
- `test/widget_test.dart` — только если это старый шаблонный тест Flutter про счётчик.

Удаления выполняет отдельный скрипт с предохранителями. Он **не удаляет** `lib/services/api/`, `lib/providers/`, `lib/screens/` и модели старого UI: они пока участвуют в обычной сборке. Удалять их до перехода UI на новые репозитории нельзя.

## Риски и ограничения

- Это архитектурный патч и обновление dev-диагностики, **не патч с новой игровой механикой/UI**.
- После неуспешной записи новых токенов в OS Secure Storage сразу после серверной ротации гостевая сессия может быть потеряна — предстоит отдельно рассмотреть восстановление аккаунтов до монетизации.
- Для `SubmitLetter` / `buyShopItem` новый `requestId` обязателен для каждой новой операции; при сетевом повторе тот же ID обязателен. Не создавайте новый UUID для повтора того же нажатия.
- Никогда не меняйте баланс или правильность буквы на стороне Flutter.
- Flutter SDK в среде автора патча не доступен: локальные `flutter analyze`, `flutter test`, Android debug сборка должны быть выполнены на вашей Windows-машине.
