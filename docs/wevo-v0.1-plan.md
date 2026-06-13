# Wevo v0.1

## Core loop
1. L'utente crea profilo
2. Compila identità gaming/social
3. Scopre altri profili tramite swipe
4. Like reciproco => match
5. Match apre una chat

## User model v0.1
- uid
- name
- age
- email
- bio
- avatarUrl
- coverUrl
- interests[]
- favoriteGames[]
- platforms[] (pc, playstation, xbox, switch, mobile)
- lookingFor[] (ranked, duo, chill, friendship, community)
- discordTag
- steamId
- spotifyArtist
- riotId
- timezone
- country
- createdAt
- likedBy[]
- matches[]

## Discover priorities
- mostra identità gaming prima della bio
- card con avatar/cover, giochi, piattaforme, vibe
- fallback mock solo se db vuoto

## Tech notes
- users collection resta principale
- swipes/matches/chats/messages in step successivi
- per ora consolidiamo users + discover + profile
