# ПРУФАНИ! — Patch 06: правильный вход в игру + фиксы тестов

Этот компактный патч накладывается **поверх Patch 05 в текущей Git-ветке**.

## Исправлено

- Убрана отдельная вкладка «Играть» в нижнем меню. Теперь четыре пункта: **Главная / Ачивки / Магазин / Профиль**.
- Главная кнопка **«Играть» / «Продолжить»** всегда открывает **выбор трёх паков**, затем выбранный пак ведёт к своим уровням. Сохранённая попытка не удаляется и может быть продолжена из сетки нужного пака.
- В выборе паков показывается та же навигация из четырёх пунктов, без ложного выделения «Главная» на вложенном экране.
- Если в показанной на главной категории ещё нет уровней или все пройдены, CTA не блокируется: **«Выбрать пак»** всё равно ведёт к категориям.
- Исправлен тест `scrolling reveals reward banner above fixed navigation`, который находил два `Text('Играть')`. Теперь проверяется именно кнопка в главной карточке.
- Добавлены widget-тесты на четыре пункта нижнего меню и маршрут «Продолжить → выбор пака».
- Сохранены реальный backend, авторизация гостя, ассеты, внешний вид карточек и звёзды в сетке уровней.

## Файлы на замену (полные)

- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/home_widgets.dart`
- `lib/features/catalog/presentation/catalog_screens.dart`
- `test/home_polish_widget_test.dart`

## Установка на Windows 11

В текущей ветке, **не переключаясь на main**, распакуй ZIP в `D:\Bloger\BlogerGrame` с заменой четырёх файлов. Если нужно сохранить резервную копию, скопируй указанные выше файлы в отдельную папку до распаковки.

```powershell
cd D:\Bloger\BlogerGrame

dart format lib\features\home\presentation\home_screen.dart lib\features\home\presentation\home_widgets.dart lib\features\catalog\presentation\catalog_screens.dart test\home_polish_widget_test.dart

flutter test test\home_polish_widget_test.dart -r expanded
flutter test
flutter analyze --no-pub
```

На физическом Android:

```powershell
& "D:\Android\Sdk\platform-tools\adb.exe" reverse tcp:8085 tcp:8085
flutter run -d R5CY5453DEY --debug `
  --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

При проверке:
1. На главной 4 пункта: Главная / Ачивки / Магазин / Профиль; `Играть` больше не дублируется в навигации.
2. Кнопка главной карточки открывает **Выбери категорию**, даже если на ней написано «Продолжить».
3. После выбора категории открываются уровни; текущая/сохранённая попытка отмечена отдельно.
4. Возврат на главную не сбрасывает гостевую сессию и не меняет кошелёк.
5. Проверить узкий экран: сетка скроллится, CTA внизу остаётся виден, звёзды не обрезаны.

После успешной проверки:

```powershell
git add -A
git diff --cached --check
git commit -m "fix(flutter): unify game entry and remove duplicate play tab"
git push
```

## Ограничение
Flutter/Dart SDK отсутствуют в среде создания этого патча: Android-сборка и тесты не запускались здесь. Их нужно подтвердить на компьютере. Никаких backend/API/БД изменений не сделано.
