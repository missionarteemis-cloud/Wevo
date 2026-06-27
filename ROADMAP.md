# Wevo roadmap

## Milestone 0 — Repo cleanup and source of truth
- confirm `~/Projects/Wevo` as canonical repo
- archive `~/Wevo`
- keep `wevo_match_demo` as separate demo/reference only
- remove overlapping seed paths
- document mock vs real flows

## Milestone 1 — Stable social core
- verify auth flows with real accounts
- stabilize profile read/write
- stabilize discovery feed from Firestore
- fix reciprocal match reliability
- validate chat creation and message persistence
- tighten Firestore rules and realistic backend loops

## Milestone 2 — Realistic testing baseline
- replace fake local fallback assumptions with explicit seeded demo users
- keep one canonical seed script and one dataset definition
- define what is demo-only and what is production-shaped
- add repeatable smoke test checklist for discovery, match, and chat

## Milestone 3 — Product polish
- clean UX across discovery, matches, profile, settings
- improve state handling and empty/error states
- reduce UI drift between screens
- validate web build and target devices

## Milestone 4 — Room system design
- define room entity model
- define online presence model
- define visit flow from discovery to room
- define room chat vs direct chat boundaries
- define furniture/customization persistence

## Milestone 5 — Room vertical slice
- enter your own room
- show online presence
- allow another user to visit
- basic movement and room chat
- prove Flutter + Flame integration without breaking the social app
