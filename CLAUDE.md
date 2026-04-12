# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

KAR1 Fitness — Flutter mobile app (Android + iOS) for a gym facility. Firebase-backed (Auth, Firestore, Storage), Provider for state, `health` package for wearable/health data sync.

Package name / iOS bundle ID: `com.kar1fitness.app`. Dart SDK `>=3.0.0 <4.0.0`, Flutter 3.0+.

## Common commands

```bash
flutter pub get                       # install deps
flutter run                           # run on connected device/emulator
flutter analyze                       # lint (uses analysis_options.yaml + flutter_lints)
flutter test                          # run all tests
flutter test test/widget_test.dart    # run a single test file
flutter test --plain-name "name"      # run a single test by name
flutter clean && flutter pub get      # reset on weird build errors

flutter build apk --release           # Android APK
flutter build appbundle --release     # Android AAB (Play Store)
flutter build ios --release           # iOS (Mac only)
```

Firebase config is generated via `flutterfire configure` into `lib/firebase_options.dart`. Android needs `android/app/google-services.json`; iOS needs `GoogleService-Info.plist` added through Xcode.

## Architecture

Layered Flutter app — UI screens → Provider → service layer → Firebase / device APIs. Entry point `lib/main.dart` initializes Firebase, then `AuthWrapper` listens to `authStateChanges` and routes to `LoginScreen` or `MainScreen` (bottom-nav shell). On login, `_ensureUserDocument` lazily creates the Firestore `users/{uid}` doc if missing — keep this invariant when touching auth or user-model fields.

`lib/` layout:
- `models/` — `user_model`, `exercise_model`, `workout_model` (Firestore-shaped data classes).
- `services/` — single responsibility wrappers around external systems:
  - `auth_service.dart` — Firebase Auth (login/signup/reset, exposes `authStateChanges`).
  - `firestore_service.dart` — all Firestore reads/writes for users, exercises, workouts.
  - `workout_recommendation_service.dart` — analyzes the last 5 workouts across 6 muscle groups (Chest, Back, Shoulders, Legs, Arms, Core) and returns exercises for the least-trained group. If you change muscle groups, update this constant list and any UI that displays them.
  - `health_service.dart` — `health` + `permission_handler` bridge to Apple Health (iOS) / Health Connect (Android 14+) / Google Fit.
- `screens/` — feature-grouped UI: `auth/`, `home/`, `profile/`, `about/`, `exercise/`, `workout/`, `debug/`, plus `main_screen.dart` (bottom nav).
- `widgets/` — shared UI (e.g. `exercise_card.dart`).
- `theme/app_theme.dart` — dark theme, KAR1 yellow `#FDD835` on dark `#1A1A1A`.

State: only `AuthService` is provided at the root via `MultiProvider` in `main.dart`. New cross-screen state should be added there rather than instantiated ad hoc.

## Firestore data model

Three collections, with security rules in the README:
- `users/{uid}` — owner-only read/write. Auto-created on first sign-in by `AuthWrapper`.
- `exercises/{id}` — read-only to authenticated users; written manually via Firebase Console. Shape: `name`, `description`, `video_url`, `thumbnail_url`, `muscle_groups[]`, `equipment[]`.
- `workouts/{id}` — readable/writable only by owner (`resource.data.user_id == request.auth.uid`). Always set `user_id` on writes or rules will reject.

Exercise videos stream via `chewie` (wrapper around `video_player`); URLs must be a player-supported format (MP4 recommended).

## Conventions

- Platform: Windows dev host — use bash/Unix syntax in commands, forward slashes in paths.
- Health integration requires runtime permissions; always go through `health_service.dart` rather than calling `health` directly.
- The recommendation algorithm assumes exercises carry `muscle_groups` matching the canonical 6-group list — new exercises must use those exact strings.
