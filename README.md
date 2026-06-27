# Wevo

Wevo is a social meeting app with a gaming-native identity.

## Product mission
Wevo helps people discover each other through vibe, play style, presence, and conversation, not just static profiles. The core app starts with discovery, matching, chat, profile, and settings. The longer-term differentiator is a social room layer where users can host, visit, and interact in lightweight 2D spaces.

## Current status
Wevo already has a functional Flutter + Firebase base:
- authentication
- user profiles with gaming/social fields
- discovery feed
- reciprocal matches
- chat model on Firestore
- dark neon visual direction

Right now the priority is not the game layer. The priority is stabilizing the core social app and replacing fake test paths with realistic data flows.

## Canonical repo
- Main app and source of truth: `~/Projects/Wevo`
- Legacy dead repo: `~/Wevo` (archive)
- Separate visual/demo experiment: `workspace/projects/wevo_match_demo` (reference only)

## Stack
- Flutter
- Firebase Auth
- Cloud Firestore
- Firebase Storage

## Main commands
- `flutter pub get`
- `flutter analyze lib`
- `flutter run -d chrome`
- `flutter build web`
- `dart run bin/seed.dart`

## Core product areas
- Discovery
- Matches and chat
- Profile
- Settings

## Docs map
- `ROADMAP.md` — milestone roadmap
- `ARCHITECTURE.md` — technical structure and data model
- `GAME_DESIGN_NOTES.md` — future room/game layer notes
- `.craw/project.md` — internal working memory for the repo
- `docs/wevo-v0.1-plan.md` — early product baseline
- `docs/chat-model-v0.1.md` — early chat data model

## Seed data policy
Wevo keeps one canonical demo seed flow:
- `bin/seed.dart`

Other older seed scripts were overlapping experiments and should not be treated as authoritative.
