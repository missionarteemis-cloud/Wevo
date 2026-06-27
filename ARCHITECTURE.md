# Wevo architecture

## App structure
- `lib/main.dart` initializes Firebase and mounts the app shell.
- `lib/screens/` contains the main product surfaces.
- `lib/services/` contains app logic for auth, users, matches, storage, and demo seeding.
- `lib/widgets/` contains reusable UI building blocks.
- `bin/seed.dart` is the canonical seed entrypoint for demo data.

## Current stack
- Flutter for app shell and product UI
- Firebase Auth for accounts
- Cloud Firestore for social state
- Firebase Storage for profile/cover media

## Firestore model
Based on the existing implementation and v0.1 docs:
- `users/{uid}`
- `swipes/{fromUid_toUid}`
- `matches/{sortedUidPair}`
- `chats/{chatId}`
- `chats/{chatId}/messages/{messageId}`

## Product surfaces
- Discover: browse user cards and trigger likes/dislikes
- Matches: see existing connections and enter chats
- Profile: edit identity, vibe, and media
- Onboarding: complete profile after registration

## Mock vs real policy
- Real behavior should come from Firestore-backed users and documents.
- Mock data may exist only as explicit demo data, not hidden fallback logic that changes product semantics.
- Demo seeding is allowed, but must write realistic Firestore entities so the app exercises real flows.

## Current known technical risks
- local mock fallbacks can mask backend truth
- overlapping seed scripts create drift
- UI iteration has moved faster than backend verification
- broad `flutter analyze` surfaces stale scripts and experiments unless the repo is cleaned
