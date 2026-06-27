# Wevo mock vs real status

## Canonical seed path
Use only:
- `node scripts/seed.mjs`

This is the canonical headless seeding direction for Wevo because the dataset includes real Firebase Auth users plus Firestore social data.

## What is real
- Firebase project: `wevo-22275`
- Firebase Auth wiring
- Firestore collections for users, swipes, matches, chats, messages
- app flows that read/write real Firebase data
- seeded demo users when created through the canonical headless script

## What is mock or demo-shaped
- hardcoded fallback user cards embedded in UI screens
- hardcoded mock chat previews/messages used when backend data is absent
- `SeedService.seedDemoData()` as an in-app dev convenience
- older ad-hoc seeding experiments in `scripts/`
- legacy repo copies that are no longer the source of truth

## Current policy
- if demo data is needed, it must be written into Firestore in realistic form
- auth-user creation belongs to the headless seeder, not to standalone Dart CLI
- hidden UI fallbacks should be reduced over time, because they distort debugging
- the current `scripts/seed.mjs` direction is correct, but still needs firebase-admin or equivalent permission bypass because client SDK writes are blocked by Firestore rules
- older seed scripts are removed to avoid ambiguity

## Legacy overlapping seed scripts to retire
- `scripts/seed_demo_data.dart`
- `scripts/seed_firestore.dart`
- `scripts/seed_demo_users.mjs`
- `scripts/seed_demo_matches.mjs`
- `scripts/seed_demo_swipes_respecting_rules.mjs`

## Why this matters
We already saw that fake users and mixed seed strategies can make matching behavior look healthier than it really is. Wevo needs realistic loops, not comforting illusions.
