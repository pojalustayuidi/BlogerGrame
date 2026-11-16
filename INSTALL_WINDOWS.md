# ПРУФАНИ! — Patch 05. Переработка категорий и выбора уровней

## Основа

**Установи этот патч поверх Patch 04** в текущей локальной ветке, где уже есть:

- `lib/features/catalog/presentation/catalog_screens.dart`
- `lib/features/catalog/presentation/catalog_widgets.dart`
- `lib/features/catalog/presentation/catalog_providers.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/home_widgets.dart`
- `assets/prufani/`

На GitHub текущая локальная ветка Patch 04 может ещё не существовать — **не переключайся на `main`**, чтобы не потерять незакоммиченные изменения. Новую ветку создавать не нужно.

## Установка Windows 11

1. Открой PowerShell и проверь, где ты находишься:

```powershell
cd D:\Bloger\BlogerGrame
git branch --show-current
git status --short
```

2. Для локальной резервной копии файлов Patch 04, которые заменяются:

```powershell
$backup = "D:\Bloger\Prufani_UI_Before_Patch05"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item "lib\features\catalog\presentation\catalog_screens.dart" $backup -Force
Copy-Item "lib\features\catalog\presentation\catalog_widgets.dart" $backup -Force
Copy-Item "lib\features\home\presentation\home_screen.dart" $backup -Force
Copy-Item "lib\features\home\presentation\home_widgets.dart" $backup -Force
Copy-Item "test\catalog_ui_test.dart" $backup -Force
```

3. **Распакуй** `Prufani_Categories_Level_Redesign_Patch_05.zip` **в корень** `D:\Bloger\BlogerGrame`, сохраняя структуру каталогов. Согласись на замену пяти файлов. Или PowerShell:

```powershell
Expand-Archive -LiteralPath "D:\Путь\к\Prufani_Categories_Level_Redesign_Patch_05.zip" -DestinationPath "D:\Bloger\BlogerGrame" -Force
```

Если удобнее, открой архив в 7-Zip и перетащи папки `lib/` и `test/` в корень проекта. Документы `INSTALL_WINDOWS.md` и `CHANGELOG_PATCH_05.md` — справочные.

## Форматирование и проверка

```powershell
cd D:\Bloger\BlogerGrame

dart format lib\features\catalog\presentation lib\features\home\presentation\home_screen.dart lib\features\home\presentation\home_widgets.dart test\catalog_ui_test.dart

flutter test test\catalog_ui_test.dart -r expanded
flutter test
flutter analyze --no-pub
```

Если в анализаторе появились `error` или `warning`, пришли полный текст. В процессе создания патча Flutter SDK на сервере не установлен, тесты здесь запустить невозможно.

## Запуск на Samsung S25+

Убедись, что Node.js backend и PostgreSQL запущены, а `http://127.0.0.1:8085` доступен с компьютера.

```powershell
& "D:\Android\Sdk\platform-tools\adb.exe" devices
& "D:\Android\Sdk\platform-tools\adb.exe" reverse tcp:8085 tcp:8085

flutter run -d R5CY5453DEY --debug `
  --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

`APP_ENV=local` и `LOCAL_DRAFT_PREVIEW=1` нужны для локальных черновых уровней, если они не опубликованы.

## Проверка глазами

1. Внизу на главной **5 вкладок**: `Главная`, `Играть`, `Ачивки`, `Магазин`, `Профиль`.
2. Вкладка `Играть` открывает **выбор паков**. Фактические `Стримеры`, `Блогеры`, `Тиктокеры` приходят из `/categories`; неподдерживаемый `Микс` не добавляется.
3. У карточек паков отображается фактическое `пройдено/всего` и жёлтый прогресс.
4. Нажатие на пак открывает **полную страницу уровней**.
5. На уровне есть шапка категории, звезда рядом с прогрессом, сетка уровней со звёздами под номерами, пагинация по 20 заданий, закреплённая жёлтая кнопка.
6. Готовые задания фиолетовые и с галочкой, текущий рекомендуемый/сохранённый уровень — жёлтый, остальные доступные — светло-лавандовые.
7. Проверить 360–412 dp, увеличенный системный шрифт, вертикальный скролл, 0 и 5 жизней, отключённый backend и повторное подключение.
8. При выборе уровня используется реальный API `startOrResumeAttempt`; если есть совпадающий сохранённый attempt — `GET /attempts/{id}`. Затем открывается существующий просмотр криптограммы. Клавиатура — отдельный следующий этап.

## Ограничения backend

`GET /levels` не сообщает **число звёзд за уровень** и **причины блокировок**. Три звезды на завершённой плитке — декоративный признак прохождения, а не серверная оценка. Незаполненные плитки **не имеют искусственных замков** — сервер разрешает выбор любого незавершённого уровня. Для ачивок пока отсутствует API — вкладка показывает `Скоро` без выдуманных достижений.

## Коммит в той же ветке

После успешной проверки:

```powershell
git add -A
git diff --cached --check
git diff --cached --stat
git commit -m "feat(flutter): redesign Prufani packs and level selection"
git push
```

Если ветка ещё не привязана к `origin`, выполняй `git push -u origin <имя-текущей-ветки>` после проверки `git branch --show-current`.
