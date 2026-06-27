# Wevo — Game Layer (design canonico)

> Documento di design **completo e canonico** del layer gioco (stanze). Sostituisce le "domande aperte" di `GAME_DESIGN_NOTES.md`, che resta come visione di alto livello. Concordato Diego + Claude, 2026-06-27. Il game layer si implementa **dopo** che il core social è stabile (vedi `ROADMAP.md`).

## 1. Visione
Wevo non è uno swipe con skin gaming. Il differenziatore è un **layer 2D sociale**: ogni utente ha una **stanza personale**, arredabile, visitabile, usata come spazio di **incontro dal vivo**. Dalla Discovery non si fa solo swipe: se l'altro è online, si **entra nella sua stanza** e si interagisce.

L'unità di tutto è **una sola**: la stanza personale con **proprietario + visitatori**. (NB: il concept visivo iniziale mostrava una "stanza pubblica" — quello era solo il framing della demo. Il modello reale è **stanze personali**.)

## 2. Regola di disponibilità stanza (DECISIONE CANONICA)
- La stanza è **visitabile quando il proprietario è ONLINE** (ovunque nell'app, **non** necessariamente dentro la stanza).
- Proprietario **offline → stanza chiusa** (non visitabile). [v1]
- Quando un visitatore entra, **il proprietario riceve un ping** "qualcuno è nella tua stanza, entra?" → è il gancio che lo tira dentro per l'incontro live. È lo stato più prezioso del prodotto.
- **v2 (futuro):** opzione del proprietario "lascia la stanza sempre aperta" (stile Habbo classico, visitabile anche da offline). Non in v1: eviterebbe "case vuote" e carico inutile di presence/moderazione.

## 3. Modello di presenza (due livelli)
1. **Online** → pallino verde **ovunque appaia il profilo** (Discovery, DM, navigazione). Letto da `presence/{uid}.online`.
2. **In stanza adesso** → indicatore più forte / pulsante + abilita **[entra nella room]**. Derivato da `presence/{uid}.inRoom == uid` (e comunque l'ingresso si abilita già su "online").

## 4. Architettura dati
Regola: **separa per quanto spesso cambia e quanto deve vivere.**

### Firestore (persistente — già attivo, regole buone)
- `rooms/{ownerUid}` = `{ ownerUid, name, theme: {wallpaper, floor}, furniture: [ {itemId, x, y, rot} ], updatedAt }`
  - **Editabile solo dal proprietario**; leggibile da chiunque loggato.
  - L'editor mobili = update di questo doc; i visitatori vedono i cambiamenti **live** via listener.
- Restano invariati: `users`, `swipes`, `matches`, `chats` (DM) + sottocollezione `messages`.

### Realtime Database (effimero, con `onDisconnect`)
- `presence/{uid}` = `{ online: bool, inRoom: ownerUid|null, lastSeen }` → pallino verde + gate ingresso. `onDisconnect` pulisce a chiusura app.
- `roomPresence/{ownerUid}/{visitorUid}` = `{ x, y, avatar, emote, enteredAt }` → chi è ora nella stanza e dove. `onDisconnect` rimuove il nodo.
- `roomChat/{ownerUid}/{msgId}` = `{ senderId, name, text, ts }` → vedi §5.

**Perché lo split (in chiaro):** Firestore = schedario (perfetto per cose salvate/rilette, ma si paga a lettura/scrittura — pessimo per "si è mosso di una casella" ripetuto). RTDB = lavagna viva (costa pochissimo per presenza/posizioni, e si auto-cancella a disconnessione).

## 5. Chat stanza — EFFIMERA
- Vive su **RTDB** (`roomChat/{ownerUid}`), **non** in Firestore. **Separata dai DM** (`chats/`): la chat-stanza non finisce mai nei DM.
- Si **cancella quando l'ultimo utente esce** dalla stanza.
- Pulizia: v1 best-effort lato client (l'ultimo che esce svuota il nodo) + namespacing per "sessione" così eventuali orfani non contano. v2: micro Cloud Function su `roomPresence` vuoto.

## 6. Flusso end-to-end
1. A in Discovery vede la card di B → l'app legge `presence/B`: `online` → pallino verde; `online` (gate) → mostra **[entra nella room]**.
2. A tocca [entra] → l'app legge `rooms/B` (mobili+tema) da Firestore, apre la schermata stanza (GameWidget Flame), scrive `roomPresence/B/A`.
3. B (online) riceve **ping** "qualcuno è nella tua stanza".
4. A vede l'avatar di B (se entra) + altri visitatori (da `roomPresence/B/*`), si muove (click casella → snap, aggiorna posizione), chatta (`roomChat/B`), fa emote.
5. B edita i mobili quando vuole → update `rooms/B` → visitatori vedono live.
6. A chiude/disconnette → `onDisconnect` pulisce presence + nodo stanza.

## 7. Stack tecnico (DECISIONE)
- **Flutter + Flame**, con Flame come **modulo embedded** (`GameWidget` dentro una schermata Flutter normale). Shell app, auth, Firebase, navigazione, Discover, DM = Flutter puro. **Solo la stanza** è un mondo Flame.
- **NO webview/JS engine (Phaser/Pixi):** frattura il progetto (due stack, ponte Flutter↔JS, passaggio auth, perf webview pessima su mobile). Riservato eventualmente a un v2 se il gioco diventasse enorme e autonomo.
- **Caveat v1:** tenere la stanza **stupida** in Flame — pavimento a griglia isometrica, avatar sprite che fanno **snap** tra caselle (no movimento libero/pathfinding), mobili sprite agganciati alle celle, fumetti chat come overlay. No fisica, no animazioni ricche all'inizio.

## 8. Rendering
- Pavimento a **griglia isometrica** (dà coordinate-cella per posizionare avatar e agganciare mobili) + parete di sfondo. Lo snap del movimento e l'editor mobili lavorano sulle celle.

## 9. Stile visivo
- **Neon cyberpunk pixel-art isometrico** ("stile Wevo"). Riferimenti: `~/Downloads/nemis app/` (concept + screenshot `lounge.png`), mockup Neon Lounge.
- Palette: base viola profondi `#0E0718` `#150c24` `#181030` `#1A1128`; neon ciano `#5FE0C5` `#62E6FF` `#8EC5FF`; magenta/rosa `#FF3E8D` `#FF5FA2` `#FFB6D4`; viola `#B98AE6` `#C9A6F0`; accenti caldi `#FF8A3D` `#FFC76A`; verde `#9EDFA6`.
- Asset Flutter già esistenti da riusare: `lib/widgets/wevo_buttons.dart`, e `wevo_match_animation.dart` (in `~/Downloads/nemis app/`).

## 10. Scope v1 (in / out)
**IN:** stanza personale propria; entrare nella propria stanza dal Profilo; entrare nella stanza altrui dalla Discovery (gate online); presence (pallino verde + in-room); avatar fisso o 3-4 skin; movimento a snap su casella; catalogo mobili piccolo + editor base; chat stanza effimera; 2-3 emote (Saluta/Balla/Emote).
**OUT (rinviato):** economia regali; movimento libero/pathfinding; customizzazione avatar spinta; stanze sempre-aperte da offline; like-da-stanza.

## 11. Ganci futuri
- **Like dalla chat-stanza** → riusa la collezione `swipes`/`matches` esistente: un "like" in stanza = swipe positivo → se reciproco, match. Forward-compatible.
- **Regalo** (bottone già nel concept) → cosmetico in v1, economia in v2.
- **Stanze sempre aperte** (v2, §2).

## 12. Sicurezza (sketch, stile regole già esistenti)
- `rooms/{ownerUid}`: write solo se `request.auth.uid == ownerUid`; read se signed-in.
- RTDB `presence/{uid}` e `roomPresence/.../{visitorUid}`: ognuno scrive **solo** il proprio nodo.
- `roomChat/{ownerUid}/*`: write se signed-in e `senderId == auth.uid` (idealmente solo se presente in `roomPresence/{ownerUid}`); read se signed-in.

## 13. Primo vertical slice (prossimo lavoro)
1. `rooms/{me}` esiste (stanza propria, mobili default).
2. Schermata stanza in Flame: griglia isometrica + il mio avatar.
3. Entro nella mia stanza dal Profilo.
4. Un secondo utente può visitarla (presence + avatar visibile).
5. Movimento a snap.
6. Chat stanza effimera.
Se questo slice gira, il concetto è provato e si itera (emote, editor mobili, ping proprietario).
