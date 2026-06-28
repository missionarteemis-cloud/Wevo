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
- The chat send path is now backend-authoritative through the callable `sendChatMessage`, while client writes to `chats`, `matches`, and `messages` are blocked by rules, because the previous direct-write model was too easy to desync and too easy to poke from the client.
- Mock chat users are no longer a fake parallel UI dataset: they only survive as special recipients that auto-reply `OK`, because keeping fake inbox content was hiding product bugs instead of helping development.
- The inbox query `chats where users arrayContains currentUid orderBy lastMessageAt desc` is now a first-class supported path with a committed Firestore composite index, because otherwise the real matches/chat UI stays randomly fragile at runtime.
- The chat UI direction is intentionally premium-editorial rather than generic modern SaaS, because Wevo needs social presence and atmosphere more than sterile efficiency.

## Lessons
- Mock Discover users can hide real match bugs. Test with real Firestore-backed users whenever behavior matters.
- A project without `.craw/project.md` forces expensive reconstruction from daily memory. Don’t repeat that.
- Multiple seed scripts are not flexibility, they are drift. Keep one canonical path.
- A seed path that cannot run in its target runtime is worse than no seed path. Validate the execution environment before declaring it canonical.
- FlutterFire plugins do not make a real standalone Dart CLI seeder. For headless Firebase auth/doc writes, use `firebase-admin` through Node with external credentials.
- The seeded Firestore verification is now real: browser snapshot in Firebase shows `users`, `swipes`, `matches`, `chats` populated in `wevo-22275`, including mixed legacy/new auth UIDs reused by the admin seeder.
- `flutter build web --no-wasm-dry-run` passes again after recreating `build/ios/SourcePackages` and `build/macos/SourcePackages` post-clean. The supposed `wevo` / `wevo_app` rename mismatch was a false lead; the real blocker was broken build-path setup for plugin copy.
- A durable integration test now exists for the real flow (demo login → discover like → match overlay → matches → send chat message). Chromedriver on `:4444` is now wired and `flutter drive` reaches the web runner, but the current Flutter web toolchain crashes in `dwds/flutter drive` (`AppConnectionException` / localhost connection refused) before test execution. The remaining blocker is the web integration harness stability, not app wiring.
- Future note only, not for now: this integration test writes against real Firestore demo data. Move it to Firebase Emulator when test isolation becomes worth the complexity.
- `flutter analyze` on the full repo will also analyze scripts and stale experiments, so scope the gate intentionally when needed.
- 2026-06-29 — Symptom: chat looked live but was partly powered by fallback/mock surfaces. Root cause: direct client writes plus fake data paths let UI appear healthy while backend truth was inconsistent. Fix: route sends through `sendChatMessage`, read previews/messages from Firestore, remove fake chat inboxes, and lock client writes in `firestore.rules`. Verify: real registered users can match and exchange messages, mock `m*` recipients only auto-reply `OK`, and no UI depends on `mockMatches/mockMessages`.
- 2026-06-29 — Symptom: real matches inbox risked failing only after deploy/runtime. Root cause: missing composite index for `chats(users arrayContains, lastMessageAt desc)`. Fix: commit `firestore.indexes.json`, wire it in `firebase.json`, deploy index to `wevo-22275`. Verify: chat previews load ordered by latest message without Firestore index errors.
- 2026-06-29 — Symptom: end-to-end web integration checks remain flaky even after app-side chat stabilization. Root cause: current web integration harness/device path hangs on `web-server` in this environment, separate from the chat implementation itself. Fix: treat the harness as the blocker, not the product flow; keep using focused analyze/build plus real Firebase validation until the harness is repaired. Verify: app builds and focused analyzes pass, while the integration runner stall reproduces independently of chat feature changes.
