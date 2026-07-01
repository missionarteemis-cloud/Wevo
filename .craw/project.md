# Wevo — project memory

## Snapshot
- Canonical repo: `~/Projects/Wevo`
- Stack: Flutter app + Firebase (Auth, Firestore, Storage), web target already used for fast iteration.
- Current phase: game layer built (iso rooms, presence/visitors, store/inventory, PixelLab avatar system with recolor-first cosmetics) on top of the stabilized social core. App is LIVE on Firebase Hosting for friend testing. See the 2026-07-01 section below.
- Product pillars: discovery, matches/chat, profile, settings, + the 2D game layer (personal rooms).
- Differentiator (now being built): personal isometric rooms, presence, customizable avatars.

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

## 2026-07-01 — Game layer + avatar system + live web deploy (frontend by Claude)

Phase has moved on: the **game layer is built** and the app is **deployed publicly** for friend testing. Diego works with Claude (Anthropic) on frontend/graphics + strategy, with Craw on backend; but Craw can now also make requested changes AND deploy.

**LIVE URL: https://wevo-22275.web.app** (Firebase Hosting).

### Deploy / Hosting (manual — this is the canonical publish path)
- Hosting is configured in `firebase.json` (`hosting.public = build/web`, SPA rewrite) + `.firebaserc` (default project `wevo-22275`). Firebase CLI logged in as `missionarteemis@gmail.com`.
- To publish changes: `flutter build web --release && firebase deploy --only hosting`.
- **`git push` does NOT deploy.** Push = source to GitHub; the live URL only updates on `firebase deploy`. (Auto-deploy via GitHub Actions was discussed but intentionally NOT set up yet — Diego wants manual control of when things go live.)
- Auth: `wevo-22275.web.app` is an auto-authorized Auth domain → registration/login work in prod. Functions (us-central1), RTDB (europe-west1), Storage all work from the hosted app.

### Game layer (branch merged to master; `docs/game-layer.md` canonical)
- Isometric room in **Flame** embedded via `GameWidget` (`lib/game/room_game.dart`, `lib/screens/room_screen.dart`), 7×7 grid (tile 64×32). Real furniture from `rooms/{ownerUid}`; multi-cell footprints, rotation, silhouette hit-test, BFS pathfinding, Move/Rotate ghost preview.
- Store→inventory→place→take loop, **server-authoritative** via Cloud Functions (`buyItem`/`placeItem`/`takeItem`). Each new callable needs `allUsers` run.invoker after deploy.
- **Presence/visitors** via RTDB (`presence`, `roomPresence`): green dot online, enter friend's room, see others move live (client interpolation). `lib/services/presence_service.dart`.
- **Depth**: painter order is now a **topological sort by separating-axis occlusion** (`_depthSorted` in room_game.dart) so long/diagonal furniture don't mis-overlap; flat rugs (height≤6) render with the floor.

### Avatar system (recolor-first) — `docs/art-spec.md`
- Sprites generated with **PixelLab.ai** (Diego's account). Pipeline: `assets/images/sprites/manifest.json` + sheets; `lib/game/sprite_assets.dart` loads them, `IsoRoom` picks sprite-or-geometric-fallback. Iso 2:1, avatar 8 directions, low-top-down.
- Two base skins in the manifest: **`avatar_base`** (male, hood up, 116×116) and **`avatar_female`** (female, NO hood, long hair, 120×120). Walk = 4 frames × 8 dir (S/SE/E/NE generated, NW/SW/W via PixelLab native mirror, N generated), composed into sheets in engine dir order (0 SE,1 S,2 SW,3 W,4 NW,5 N,6 NE,7 E).
- **Cosmetics = recolor-first (free, in-engine)** because PixelLab "States" cost 20-40 generations each (too pricey for a catalog). `lib/game/avatar_recolor.dart` recolors hoodie (luminance ramp) + skin (relative) + hair (relative, only on hair-visible bases) via per-channel masks. `AvatarFigure` (`lib/models/avatar_figure.dart`) = structured look {base, hoodie, skin, hair}, persisted on `users/{uid}.figure` (server-authoritative, `coins` unchanged rule allows it), propagated to visitors via RTDB roomPresence (base/hoodie/skin/hair). UI: room dock "Aspetto" (Uomo/Donna + colore Felpa/Pelle/Capelli), scrollable sheet.
- Future avatar ideas (not done): hood on/off toggle = needs both hood-up and hood-down variants per gender (more generations); overlay accessories (hats) to test; cosmetics as catalog/inventory items (economy).

### Working rules (unchanged, reinforced)
- **Diego tests everything by hand** (permanent pillar). For sprite/asset changes he does a FULL restart (q + `flutter run`), not hot reload.
- Commit only confirmed work; **push only after Diego confirms**. Service-account key stays OUTSIDE the repo (`~/.config/wevo/serviceAccount.json`), never committed/echoed.
- After changing avatar art: re-export from PixelLab, recompose sheets with ImageMagick in engine dir order, update `manifest.json` frame size/anchor, restart.
