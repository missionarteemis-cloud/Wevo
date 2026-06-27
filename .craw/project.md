# Wevo — project memory

## Snapshot
- Canonical repo: `~/Projects/Wevo`
- Stack: Flutter app + Firebase (Auth, Firestore, Storage), web target already used for fast iteration.
- Current phase: core social app stabilization before any game layer.
- Product pillars: discovery, matches/chat, profile, settings.
- Differentiator to plan later: personal rooms + lightweight social 2D layer.

## Commands
- Install deps: `flutter pub get`
- Analyze focused app code: `flutter analyze lib`
- Run web locally: `flutter run -d chrome`
- Build web: `flutter build web`
- Seed headless dataset: `GOOGLE_APPLICATION_CREDENTIALS=~/.config/wevo/serviceAccount.json node scripts/seed.mjs`
- Seed in-app dev dataset: trigger `SeedService.seedDemoData()` from the profile dev action inside the Flutter app

## Architecture in 5 lines
- `lib/main.dart` boots Firebase and hosts the main shell tabs.
- `lib/screens/*` contains the product surfaces: discover, matches/chat, profile, onboarding.
- `lib/services/*` handles Firebase-facing logic like auth, users, matches, storage.
- Firestore uses `users`, `swipes`, `matches`, `chats/{chatId}/messages` as the core social model.
- Headless auth-account seeding must use one canonical Node script, not Dart CLI, because Firebase Flutter plugins do not run in standalone Dart.

## Decisions
- `~/Projects/Wevo` is the single source of truth for the real app, because it is the active GitHub-backed repo and contains the current product work.
- `workspace/projects/wevo_match_demo` remains a separate throwaway demo/reference, not the app repo, because mixing it into the main repo would blur history and architecture.
- `~/Wevo` is legacy dead material from `nemis_app` days and should be archived, not developed further.
- We prioritize real Firestore-backed flows over in-app mock fallbacks, because the match logic already got distorted by fake data.
- `bin/seed.dart` was a false canonical path and was removed, because Flutter Firebase plugins cannot be used from standalone Dart CLI.
- Current canonical seeding path is `scripts/seed.mjs` via `firebase-admin`, with credentials injected through `GOOGLE_APPLICATION_CREDENTIALS` pointing to a JSON key stored outside the repo.
- `SeedService` remains an in-app dev convenience only, not the canonical seeding channel.
- The game layer waits until the social core is documented, seeded coherently, and technically stable.

## Lessons
- Mock Discover users can hide real match bugs. Test with real Firestore-backed users whenever behavior matters.
- A project without `.craw/project.md` forces expensive reconstruction from daily memory. Don’t repeat that.
- Multiple seed scripts are not flexibility, they are drift. Keep one canonical path.
- A seed path that cannot run in its target runtime is worse than no seed path. Validate the execution environment before declaring it canonical.
- FlutterFire plugins do not make a real standalone Dart CLI seeder. For headless Firebase auth/doc writes, use `firebase-admin` through Node with external credentials.
- `flutter analyze` on the full repo will also analyze scripts and stale experiments, so scope the gate intentionally when needed.
