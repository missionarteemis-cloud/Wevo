# Wevo game design notes

> ➡️ **Il design canonico e dettagliato del game layer è in [`docs/game-layer.md`](docs/game-layer.md)** (decisioni prese, modello dati Firestore+RTDB, regola disponibilità stanza, scope v1, stile, primo slice). Questo file resta come visione di alto livello; le "Questions to answer" qui sotto sono ormai **risposte** in `docs/game-layer.md`.

This file is intentionally future-facing. The game layer does not start until the social core is stable.

## Design intent
Wevo is not just a swipe app with a gaming skin. The long-term differentiator is a social 2D layer where each user has a room that can be visited, personalized, and used as a live interaction space.

## Core fantasy
- every user has a room
- rooms can be decorated
- users can be present inside their room
- other users can enter when presence allows it
- discovery can lead either to swipe/match or direct room visit
- room presence makes the profile feel alive, not static

## Recommended technical direction
- keep Flutter for the app shell
- use Flame only for the embedded room/game module
- do not rebuild the whole app as a game client

## Questions to answer before implementation
- what counts as online presence?
- can anyone enter a room, or only matched users?
- is room chat the same as DM chat or a separate channel?
- how is furniture stored and rendered?
- what is the minimum avatar/movement model?
- what is the smallest vertical slice that proves the concept?

## Recommended first slice
- own room exists
- user can enter it
- presence visible from discovery/profile
- second user can visit
- basic movement
- room chat

## Anti-chaos rule
No room system implementation before:
- repo cleanup is done
- seed strategy is singular and documented
- auth/profile/discovery/match/chat are stable enough to trust
