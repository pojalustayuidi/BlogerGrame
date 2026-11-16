# BlogerGrame Flutter audit (2026-11-16)

## Repository states verified

- Flutter: `pojalustayuidi/BlogerGrame`, branch `main`, commit `0d7d831da10ee824a717662a84c43160227a5e28` (2026-06-19).
- Backend: `pojalustayuidi/BlogerGrameGame-backend`, branch `main`, commit `c832849c3d1185026dd2acf33aa9340578a3fed2` (2026-11-16).
- Backend PR #5 and #6: both merged; CI on main succeeded at 2026-11-16T18:53:38Z.

## Keep intact

- Riverpod-based app shell and screen navigation for now.
- `lib/screens/menu_screen/menu_screen.dart` and menu widgets (blue gradient + white panels).
- `lib/screens/level_screen/level_widgets/phrase_cell.dart`: selected, correct/incorrect animations.
- `phrase_board_card.dart`: adaptive card shell and scrolling.
- `virtual_keyboard_widget.dart`: keyboard visuals; its full-phrase dependency must be removed.
- `level_compite_dialog.dart`: visually reuse for victory/author bonus.
- `lib/screens/store_screen/shope_screen.dart`, `settings_screen` and bundled assets.
- `settings_provider.dart`: SharedPreferences is fine for non-sensitive audio preferences.

## Replace or rewire

1. `services/api/level_servisec.dart`: old `/levels` + int ID + full quote/author.
2. `services/api/player_service.dart`: old `playerId`, client-authoritative coin/progress/life endpoints.
3. `services/api/player_lives_service.dart`: old direct decrement/update endpoints.
4. `services/api/shop_service.dart`: old shop route and purchase body; server uses SKU+requestId.
5. `services/api/promo_service.dart`: old `/redeem` is not the current v1 contract.
6. `services/models/level.dart`: int ID/quote/author/reward leaks solution; real level ID is UUID.
7. `services/models/shop_item.dart`: adapt to `{sku,kind,quantity,costCoins}`.
8. `providers/level_provider.dart`: call authenticated `/api/v1/game/levels`, category filter.
9. `providers/player_provider.dart`: observe `/api/v1/game/wallet`, never POST client balances.
10. `providers/life_timer_provider.dart`: local 15-minute timer is obsolete, use server `nextLifeAt` and 30-minute configuration.
11. `providers/game_provider.dart`: local answer matching, five-mistake loss, and client progress payout are obsolete.
12. `screens/loading_screen/loading_screen.dart`: old dual fetch and `levels.first` on empty list; replace after auth integration.
13. `screens/level_screen/level_widgets/custom_level_appbar_widget.dart`: home action calls `PlayerService.updateProgress` (!), remove.
14. `screens/level_screen/level_widgets/phrase_display_widget.dart`: currently uses `level.quote` to derive words. Adapt to server `layout` separator cells.
15. `screens/level_screen/level_widgets/virtual_keyboard_widget.dart`: currently uses `fullPhrase` for completion logic. Server must determine completion.
16. `screens/store_screen/shope_screen.dart`: updates coins/lives/hints locally after purchase; show backend wallet instead.
17. `test/widget_test.dart`: Flutter counter sample, not a meaningful game test.
18. `android/app/build.gradle`: release uses debug signing; block for production.

The old `lib/lib.zip` and `lib/lib.rar` need a source-history review before removal; patch 01 does not delete them.

## Actual backend contract invariants

- `POST /api/v1/auth/guest` responds with `{player,accessToken,refreshToken,accessExpiresAt,refreshExpiresAt,...}`.
- `GET /api/v1/game/categories` -> `{categories:[{slug,title,levels}]}`.
- `GET /api/v1/game/levels?category=streamers` -> `{levels:[{id,category,number,difficulty,letters,preview,completed}],draftPreview}`.
- `POST /api/v1/game/levels/<UUID>/attempts` -> `{created,attempt}`; idempotent resume of an unfinished level.
- `GET /api/v1/game/attempts/<UUID>` -> `{attempt:{id,layout,notes,mistakes,triesRemaining,triesPerLife,status,...}}`.
- Each `layout[]` item has `position`, `type:'letter'`, `number`, `given`, `letter`, optionally `hinted`, or `type:'separator'` with `value`.
- `PATCH /api/v1/game/attempts/<UUID>/cells/<position>` requires `{letter,requestId}`. Each new press gets a new UUID; retry exactly the same input with the same UUID.
- Wrong letter is not stored, three errors cost one life, player can resume if life hits 0. No automatic duplicate-number filling.
- Successful last cell automatically solves. Bonus answered via `POST /attempts/:id/bonus`.
- Wallet is `GET /api/v1/game/wallet` -> `{wallet:{coins,lives,hints,maxLives,maxHints,lifeRegenMinutes,nextLifeAt}}`.
- `POST /api/v1/game/shop/purchases` requires only `{sku,requestId}`.
- Draft content invisible without `APP_ENV=local` and `LOCAL_DRAFT_PREVIEW=1`.

## Incremental implementation plan

### 01 — Backend foundation (this archive)

- Secure token storage, token rotation, 401 retry once, shared Dio wrapper.
- Models for real category/level/wallet/attempt layout and typed methods for game/mutations.
- A separate Android debug entry point to verify real guest, categories, wallet, and saved attempt.
- No deletions/replacements of existing game and screens.

### 02 — Boot flow and catalog in the real UI

- Route regular `main.dart` boot through the authenticated API.
- Rewire current menu widgets and level progression to UUID/catalog.
- Handle empty catalog, 401, offline and loading without crashing.
- Fetch wallet and show correct lives/coins/hints; timer is a countdown to `nextLifeAt`, followed by a wallet refresh.

### 03 — Server-authoritative cryptogram

- Adapt existing `PhraseCell` and board to `layout`; keep visual styling/animations.
- Rewrite game provider around server attempt, state keyed by attempt ID, single in-flight letter per cell.
- On each press: generate UUID, disable concurrent same-cell submissions, PATCH, apply reply, preserve requestId for exact network retry.
- On network failure: GET attempt before allowing a new press; never infer correctness locally.
- Map error states, three tries, five hearts, zero-life lock; preserve `Ё` keyboard.

### 04 — Hints, notes, win + author bonus

- Existing hint button talks to `/hints/reveal`; accept wallet returned by server.
- Add number-based notebook via `/notes/:number`; it never fills cells.
- On `solved`, show creator options, handle null skip, reveal quote/source only afterwards.
- Continue/restart from backend GET; progress persisted on server.

### 05 — Shop and polish

- Adapt `ShopScreen` to server offers, SKU, UUID requestId, server wallet.
- Loading/error/offline, narrower Android screens, animations, screen reader labels.
- Tests for restore, repeated numbered cells, idempotency, lives, author bonus.
- Release cleanup: signing, HTTPS, content rights and attribution review.

### Monetization (separate later stage)

- Rewarded ad confirmation and billing verification must be implemented server-side.
- Do not accept client commands that grant resources on their own.
