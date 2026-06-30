# Wevo — Spec Arte (pixel-art isometrica)

> Spec **canonica** per produrre gli sprite (avatar + mobili) con coerenza tra strumenti diversi (PixelLab/Retro Diffusion/artista/ComfyUI). Il principio: **la coerenza viene dalla spec, non dalla fonte**. Tutti gli asset rispettano gli STESSI parametri di griglia, densità pixel, luce e palette. Fondata su convenzioni reali (iso 2:1, sistema avatar Habbo a 8 direzioni — vedi §10).

---

## 1. Principio di coerenza (le 4 ancore)
Qualsiasi sprite, da qualsiasi tool, DEVE rispettare:
1. **Densità pixel unica** (§3) — stessa dimensione del "pixel" su tutti gli asset.
2. **Direzione di luce unica** (§4) — luce sempre dallo stesso lato.
3. **Palette + ramp condivisi** (§5).
4. **Contorni coerenti** (§6).
Se questi 4 combaciano, asset di fonti diverse sembrano lo stesso gioco.

## 2. Geometria isometrica
- Proiezione **dimetrica 2:1** ("video-game isometric"): per ogni 2 px in orizzontale, 1 px in verticale (pendenza 1:2). Il rombo del pavimento è **largo il doppio dell'altezza**.
- **Tile pavimento: 64 × 32 px** (rombo). *Già usato nel motore: `tileW=64`, `tileH=32` in `lib/game/room_game.dart` → gli sprite ci cascano dentro senza riscalare.*
- Vertici del rombo (relativi al centro cella C): top `(C.x, C.y−16)`, right `(C.x+32, C.y)`, bottom `(C.x, C.y+16)`, left `(C.x−32, C.y)`.

## 3. Densità pixel & griglia (la coerenza che conta)
- **Autorare a 1× (risoluzione nativa).** 1 pixel d'arte = 1 pixel a zoom 1×. **Niente anti-aliasing**, niente mezze tinte sui bordi: pixel duri.
- **Un solo "pixel size".** Tutti gli sprite usano la stessa griglia: nessun asset con "pixeloni" e altri con pixel fini. Se generi con AI a risoluzione alta, **riduci a griglia nativa** (downscale nearest-neighbor) e ripulisci, così la densità è identità ovunque.
- **Zoom intero.** A schermo si scala solo per multipli interi (1×, 2×, 3×) con nearest-neighbor — mai scale frazionarie (sfocano i pixel).
- **Dithering** (se usato per sfumature): pattern regolare e parsimonioso, stessa "grana" su tutti gli asset.

## 4. Luce (una sola direzione, sempre)
- **Luce dall'ALTO-SINISTRA** (NO). Conseguenze fisse su ogni sprite:
  - Facce/superfici rivolte in **alto-sinistra** = più chiare (highlight).
  - Facce in **basso-destra** = più scure (ombra).
  - **Ombra a terra**: ellisse morbida sotto l'oggetto/avatar, spostata in basso-destra, semi-trasparente.
- Mai invertire la luce tra un asset e l'altro: è il motivo #1 per cui set misti "stonano".

## 5. Palette (neon cyberpunk Wevo)
Palette limitata e condivisa. Ogni colore-base ha un **ramp di 3 toni** (highlight / mid / shadow).
- **Base scure (ambiente/ombre):** `#0E0718` `#150C24` `#181030` `#1A1128` `#251C3D`
- **Neon ciano:** `#62E6FF` (mid) → hi `#8EC5FF`, sh `#2E6FA8`
- **Neon magenta/rosa:** `#FF5FA2` (mid) → hi `#FFB6D4`, sh `#B23A6E`
- **Viola:** `#B98AE6` / `#C9A6F0` / `#9A6FD0`
- **Verde:** `#9EDFA6` · **Caldi:** `#FF8A3D` `#FFC76A`
- **Regola:** ogni sprite usa **pochi** colori del set (5-8), con il ramp per le ombre. Niente colori fuori palette. (Le sfumature si fanno col ramp + dithering, non con gradienti morbidi.)

## 6. Contorni
- **Outline selettivo scuro** sul perimetro esterno (1 px), colore = tono più scuro della palette dell'oggetto (NON nero puro — usa `#0E0718` o lo shadow del ramp).
- **Niente outline interno** tra le superfici dello stesso oggetto: si separano con le ombre del ramp.

---

## 7. Avatar (sprite sheet animato)
Sistema **a layer** come Habbo, ma per iniziare basta **un personaggio base** (poi si aggiungono skin/vestiti). Parti layer (per il futuro): testa `hd`, capelli `hr`, busto `ch`, gambe `lg`, scarpe `sh` (+ `ha` cappello).

### Dimensioni & anchor (fisse per allineare tutto)
- **Canvas frame: 64 × 96 px** (largo come un tile; alto per corpo + testa).
- **Altezza personaggio:** ~**52 px** (testa→piedi), larghezza ~**22-26 px**.
- **Anchor (piedi):** punto `(32, 84)` nel canvas → si appoggia al **centro cella**. Sotto i piedi ~12 px per l'ombra.

### Direzioni
- **8 direzioni** `0..7` in senso orario (convenzione Habbo). `0` = rivolto verso il basso-destra (verso la camera), poi orario.
- Minimo accettabile per partire: **4 direzioni** (NE, SE, SW, NW) + **mirror** orizzontale per le altre 4. Ideale: 8 disegnate.

### Animazioni (pixel "a scatti voluti", non fluide)
- **idle (`std`)**: 1-2 frame (respiro leggero).
- **walk (`wlk`)**: **4 frame** per direzione (contatto → passaggio → contatto → passaggio) — gambe/braccia che si muovono. *(Habbo: std=1 frame, walk=più frame.)*
- (Futuri: `wave`/saluta, `dance`/balla, `sit`/seduto, `lay`/sdraiato.)

### Layout dello sprite sheet
- Griglia di celle **64×96**, una cella per `(direzione, frame)`.
- Convenzione: **righe = direzioni (0..7)**, **colonne = frame** dell'azione. Un foglio per azione (`idle`, `walk`) oppure un foglio unico con blocchi per azione.
- Naming file (ispirato Habbo, semplificato): `wevo_avatar_<azione>_<dir>_<frame>.png` per frame singoli, **oppure** un foglio `wevo_avatar_<azione>.png` + manifest (§9).

## 8. Mobili (sprite isometrici)
- Autorati sulla **stessa griglia/densità/luce/palette**.
- **Footprint** in celle (1×1, 2×2, 3×1…). Lo sprite copre il rombo del footprint + l'altezza dell'oggetto, con la stessa luce NO.
- **Anchor:** il **vertice posteriore** del footprint (la cella `(x, y)` di ancoraggio) allineato al motore. Definisci l'offset pixel dall'anchor all'angolo in alto-sinistra dello sprite.
- **Animazione opzionale:** alcuni mobili 2-4 frame (es. lampada che pulsa, schermo). Stessa logica del manifest.

## 9. Manifest (come si aggancia al motore)
Ogni sprite entra via un **manifest JSON** (`assets/images/sprites/manifest.json`) — aggiungere un asset = droppare il PNG + una riga, zero codice. Formato **realmente implementato** (`lib/game/sprite_assets.dart`):
```json
{
  "avatar_base": {
    "type": "avatar",
    "frameW": 64, "frameH": 96,
    "anchor": [32, 84],
    "directions": 8,
    "actions": { "idle": {"sheet": "sprites/avatar_idle.png", "frames": 2, "fps": 2},
                 "walk": {"sheet": "sprites/avatar_walk.png", "frames": 4, "fps": 8} }
  },
  "sofa_neon_2x1": { "type": "furniture", "sheet": "sprites/sofa_neon_2x1.png", "anchor": [64, 80] }
}
```
- **Avatar:** un foglio per azione, righe = direzioni (`0..7`), colonne = frame; `anchor` = piedi (px). Con meno di 8 direzioni: `"directions": 4` (mirror auto) o `"dirMap"` esplicito (8 coppie `[riga, mirror]`).
- **Mobili:** chiave = `itemId` del catalogo; frame singolo; `anchor` = punto d'appoggio a terra (px, default bottom-center).
- I path `sheet` sono relativi a `assets/images/` (prefix Flame). Tutto **best-effort**: PNG mancante → fallback geometrico per quell'elemento.

Il caricamento è in `RoomSprites.load()`; il motore (`IsoRoom`) sceglie sprite-vs-geometria a runtime. *Lato codice già pronto: catalogo `itemId` (`lib/game/furniture_catalog.dart`), loader + render con fallback (`lib/game/sprite_assets.dart`, `lib/game/room_game.dart`).*

## 10. Cosa produrre per primo (ordine di impatto)
1. **1 personaggio base**: `idle` (2 frame) + `walk` (4 frame) × 4 direzioni (+mirror). → il salto visivo più grande.
2. **Tile pavimento + parete** in palette (il "set" della stanza).
3. **I 4-7 mobili dello store** (sofa/tavolo/lampada/letto/arcade/tappeto/frigo) come sprite.
4. Poi: 8 direzioni piene, emote (`wave`/`dance`), skin/vestiti a layer.

## 11. Spunti tecnici da Habbo (fonti)
- **Iso 2:1** (largo 2× l'altezza) = convenzione standard, confermata per Habbo.
- **Avatar a 8 direzioni** (`0..7` orario), `std` = 1 frame, `walk`/`wave` = più frame.
- **Composizione a layer**: parti `hd/hr/ha/ch/lg/sh` combinate (figura = `figureType-imageID-colorID...`). Naming immagini `lib_size_action_part_id_direction_frame`.
- Per iniziare **non** serve il sistema a layer completo (è tanto lavoro): basta un personaggio intero; i layer si aggiungono dopo per skin/vestiti.

Fonti: dev.to "Habbo: Avatar Rendering Basics"; clintbellanger.net "Isometric Tiles"; spritedatabase Habbo; community Habbo.
