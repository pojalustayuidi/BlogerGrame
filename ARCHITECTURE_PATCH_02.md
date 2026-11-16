# Patch 02 — архитектура и решения

## Основная структура

```text
lib/
  core/
    di/backend_providers.dart          # Riverpod composition root
    network/                             # Dio client + auth contract + errors
  features/
    auth/
      domain/auth_repository.dart
      data/auth_repository_impl.dart
      data/guest_session_manager.dart
      data/secure_session_store.dart
    catalog/
      domain/catalog_models.dart
      domain/catalog_repository.dart
      data/catalog_mapper.dart
      data/catalog_repository_impl.dart
    game/
      domain/game_models.dart
      domain/game_repository.dart
      domain/usecases/{start_or_resume_attempt,submit_letter}.dart
      data/game_mapper.dart
      data/game_repository_impl.dart
    economy/
      domain/economy_models.dart
      domain/economy_repository.dart
      data/economy_mapper.dart
      data/economy_repository_impl.dart
  dev/backend_check_screen.dart         # Riverpod/feature contracts, not BackendApi
  main_api_smoke.dart                    # ProviderScope for diagnostic entrypoint
```

## Направление зависимостей

Presentation → интерфейсы Domain / Use Cases. Data → Domain. `core/network` знает только `AccessTokenSource`, но не конкретный менеджер гостевой сессии. `backend_providers.dart` соединяет реализации.

`Domain` не импортирует `Flutter`, `Dio`, `SharedPreferences` или `flutter_secure_storage`. JSON `fromJson` находится только в `data/*_mapper.dart`.

## Настоящий backend-контракт

- `POST /api/v1/auth/guest` / `POST /api/v1/auth/refresh` / `GET /api/v1/auth/me`.
- `GET /api/v1/game/categories`, `GET /api/v1/game/levels?category=...`.
- `POST /api/v1/game/levels/:id/attempts`, `GET /api/v1/game/attempts/:id`.
- `PATCH /api/v1/game/attempts/:id/cells/:position` c `{letter, requestId}`.
- `POST /api/v1/game/attempts/:id/hints/reveal` c `{position}`.
- `PUT /api/v1/game/attempts/:id/notes/:number` c `{letter, comment}`.
- `POST /api/v1/game/attempts/:id/bonus` c `{guessedCreatorId}`.
- `GET /api/v1/game/wallet`, `GET /api/v1/game/shop`, `POST /api/v1/game/shop/purchases`.

`GameRepositoryImpl` не знает правильный текст и не начисляет награды: он преобразует ответ сервера в типизированные объекты. `LevelSummary` не раскрывает цитату или автора. По одинаковому номеру клетки *не заполняются* автоматически.

## Не входит в этот патч

- Новый UI и игровое меню, изменение старых экранов.
- Перенос старых Riverpod providers на новые репозитории (сделаем вместе с UI).
- Удаление старых API-классов, пока они нужны старому UI.
- Рекламные награды и IAP.
