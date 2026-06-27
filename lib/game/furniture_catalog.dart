import 'dart:ui';

import '../theme.dart';

/// Catalogo arredo lato client (manifest stub).
///
/// Mappa `itemId` → metadati di rendering/comportamento. Per ora geometria
/// placeholder (footprint + colore + altezza); quando ci saranno gli sprite
/// pixel-art, qui si aggiunge `assetRef` e si legge dal manifest sprite.
/// È il punto in cui aggiungere un mobile = una riga, senza toccare il backend.
class FurnitureDef {
  final String name;
  final String description;
  final int w; // footprint larghezza (celle)
  final int h; // footprint profondità (celle)
  final double height; // altezza in pixel (box placeholder)
  final Color color;
  final String interaction; // 'none' | 'sit' | 'lie'

  const FurnitureDef({
    required this.name,
    required this.description,
    this.w = 1,
    this.h = 1,
    this.height = 26,
    required this.color,
    this.interaction = 'none',
  });
}

const _fallback = FurnitureDef(
  name: 'Oggetto',
  description: 'Un oggetto della stanza.',
  color: WevoColors.periwinkle,
);

const Map<String, FurnitureDef> furnitureCatalog = {
  'sofa_neon_2x1': FurnitureDef(
    name: 'Divano Neon',
    description: 'Comodo e luminoso. Ci si potrà sedere.',
    w: 2,
    h: 1,
    height: 22,
    color: WevoColors.pink,
    interaction: 'sit',
  ),
  'table_low_2x2': FurnitureDef(
    name: 'Tavolo basso',
    description: 'Un tavolino centrale 2×2.',
    w: 2,
    h: 2,
    height: 18,
    color: WevoColors.periwinkle,
  ),
  'lamp_pillar_1x1': FurnitureDef(
    name: 'Lampada a colonna',
    description: 'Diffonde una luce neon nella stanza.',
    height: 52,
    color: WevoColors.cyan,
  ),
  'bed_loft_3x1': FurnitureDef(
    name: 'Letto loft',
    description: 'Ci si potrà sdraiare.',
    w: 3,
    h: 1,
    height: 26,
    color: WevoColors.sage,
    interaction: 'lie',
  ),
  'arcade_duo_2x2': FurnitureDef(
    name: 'Arcade Duo',
    description: 'Cabinato arcade per due.',
    w: 2,
    h: 2,
    height: 48,
    color: WevoColors.cyan,
  ),
  'neon_rug_3x2': FurnitureDef(
    name: 'Tappeto Neon',
    description: 'Un tappeto luminoso 3×2.',
    w: 3,
    h: 2,
    height: 4,
    color: WevoColors.periwinkle,
  ),
  'fridge_pixel_1x1': FurnitureDef(
    name: 'Frigo Pixel',
    description: 'Tiene fresche le vibe.',
    height: 44,
    color: WevoColors.sage,
  ),
};

FurnitureDef furnitureDef(String itemId) => furnitureCatalog[itemId] ?? _fallback;

/// Footprint effettivo dato l'item e la rotazione (gradi 0/90/180/270).
/// A 90/270 la larghezza/profondità si scambiano.
(int, int) footprintWH(FurnitureDef def, int rot) {
  final swap = ((rot % 360) ~/ 90) % 2 == 1;
  return swap ? (def.h, def.w) : (def.w, def.h);
}
