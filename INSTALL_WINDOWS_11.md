# BlogerGrame — Patch 01: safe guest session + API contract

## Scope

This archive adds the real backend adapter, secure session storage, models,
Dio request wrapper with synchronized refresh, and a development-only screen
that displays the real guest, wallet, categories, levels and saved puzzle layout.
The normal `lib/main.dart` entry point is **unchanged**. Existing UI/providers
are deliberately not wired to the new backend yet. No gameplay systems were
replaced or deleted in Patch 01.

Source baseline: GitHub `pojalustayuidi/BlogerGrame` `main`, inspected on
2026-11-16. Backend contract: `pojalustayuidi/BlogerGrameGame-backend` `main`,
after PR #5 and #6.

## Install on Windows 11 (PowerShell)

1. Commit or stash your existing local work.
2. In the Flutter project root, first create the branch on the latest main:

```powershell
git switch main
git pull --ff-only
git switch -c feat/flutter-01-backend-foundation
```

3. Now copy the **contents** of this ZIP into the Flutter project root,
   preserving `lib/`, `android/`, `test/` paths. Confirm overwrite for
   `pubspec.yaml` and the two Android manifests. Do not delete other files.
4. Then run:

```powershell
flutter pub get
flutter analyze
flutter test test/backend_models_test.dart
flutter devices
```

`flutter analyze` may reveal preexisting warnings from legacy code. The default
`test/widget_test.dart` is Flutter boilerplate and not a valid game test.

### Backend terminal

```powershell
cd D:\Bloger\BlogerGrameGame-backend
docker compose up -d
npm run db:migrate
npm run db:seed
npm run content:import-drafts
notepad .env
```

Set `LOCAL_DRAFT_PREVIEW=1` in `.env`; keep `HOST=127.0.0.1` and port `8085`.
Then restart the backend (stop previous npm run process with Ctrl+C):

```powershell
npm run dev
```

In a second PowerShell terminal:

```powershell
Invoke-RestMethod http://127.0.0.1:8085/health
```

### Android terminal (USB device with USB debugging)

```powershell
adb devices
adb reverse tcp:8085 tcp:8085
adb reverse --list
cd D:\Bloger\BlogerGrame
flutter run -t lib/main_api_smoke.dart --debug `
  --dart-define=BLOGERGRAME_API_URL=http://127.0.0.1:8085
```

`adb reverse` lets the Android app reach the host's localhost-only backend.
If `adb` isn't on PATH, use the copy in your Android SDK `platform-tools`.
For Android emulator, `adb reverse` can also be used.

## Expected manual checks

- New guest created only once; shows 30 coins, 5 lives and 2 hints.
- Categories `streamers` 22, `bloggers` 8, `tiktokers` 12 with local draft preview.
- Selecting category returns its real levels; level IDs are UUID strings.
- Tapping an unfinished level opens the saved numeric puzzle layout. Returning
  and tapping again fetches the **same** in-progress attempt.
- Relaunching the debug app restores the same guest ID from secure storage.
- If the backend is stopped, tapping refresh gives a visible connection error.

To run the old app unchanged, use `flutter run -t lib/main.dart`. It still
points to legacy endpoints and is **not** compatible with the new backend.

## Safety notes

- Never store the admin API key in Flutter.
- Do not commit `.env`, access tokens, refresh tokens, or real test session logs.
- Refresh rotates both tokens and stores them as one Secure Storage record.
- If a refresh token is rejected, the client reports `SESSION_EXPIRED` and does
  not silently create another user (which would lose access to the old guest).
- Offline/time-out mutations are **not** automatically retried. Patch 02 must
  assign and preserve UUID request IDs per keyboard press and use server replies
  as the sole source of state.
- Cleartext HTTP is enabled only for Android debug builds. Production needs HTTPS.
- The backend is local-only, never make it publicly reachable without hardening.

## Commit

```powershell
git add pubspec.yaml pubspec.lock android/app/src/debug/AndroidManifest.xml `
  android/app/src/main/AndroidManifest.xml lib/core/backend lib/dev `
  lib/main_api_smoke.dart test/backend_models_test.dart
git commit -m "feat(flutter): add secure guest session and backend API foundation"
```

Do not create a PR/merge until local Flutter tests and the phone API-check pass.
