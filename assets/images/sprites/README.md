# Sprite del game layer

Qui vanno i PNG pixel-art (avatar + mobili). Spec completa: `docs/art-spec.md`.

## Come aggiungere arte (plug-and-play)
1. Esporta i PNG secondo la spec e **mettili flat in questa cartella** (niente sottocartelle: così bastano già registrati in `pubspec.yaml`).
2. Abilita/aggiorna l'entry in [`manifest.json`](manifest.json).
3. **Full restart** dell'app (non hot reload): gli asset si caricano a `onLoad`.

Finché un PNG manca, quell'elemento usa il **fallback geometrico** (le forme attuali) — l'app non si rompe mai.

## File attesi (nomi nel manifest)
**Avatar** (foglio = righe×colonne, riga = direzione 0..7, colonna = frame):
- `avatar_idle.png` — 8 righe × 2 colonne, frame 64×96, ancora piedi (32,84)
- `avatar_walk.png` — 8 righe × 4 colonne, idem

> Con sole 4 direzioni disegnate: imposta `"directions": 4` nel manifest (le altre 4 vengono specchiate). Per un controllo fine usa `"dirMap"` (8 coppie `[riga, mirror]`).

**Mobili**
- base: frame singolo, ancora = punto d'appoggio a terra bottom-center
- opzionale: **sheet 4 direzioni** in una sola riga (`directions: 4`, `frameW`, `frameH` nel manifest), usato in base alla rotazione 0/90/180/270

`sofa_neon_2x1.png` · `table_low_2x2.png` · `lamp_pillar_1x1.png` · `bed_loft_3x1.png` · `arcade_duo_2x2.png` · `neon_rug_3x2.png` · `fridge_pixel_1x1.png`

Per un mobile ruotabile con 4 viste (es. Kookino): esporta un PNG orizzontale con **4 frame affiancati** nello stesso ordine delle rotazioni cardinali del gioco:
- frame 0 = rot 0°
- frame 1 = rot 90°
- frame 2 = rot 180°
- frame 3 = rot 270°

L'`anchor` nel manifest è in pixel `[x, y]` dal top-left del frame: regolalo se il mobile "galleggia" o "sprofonda".
