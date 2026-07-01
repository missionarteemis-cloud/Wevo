import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'avatar_recolor.dart';

/// Caricamento sprite del game layer (vedi docs/art-spec.md §9).
///
/// Tutto **best-effort**: se il manifest o i PNG mancano (es. arte non ancora
/// prodotta), [hasAvatar] resta false e [furnitureSprite] torna null → il motore
/// (`IsoRoom`) usa il **fallback geometrico** già esistente. Aggiungere arte =
/// droppare i PNG in `assets/images/sprites/` e una riga nel manifest, zero codice.
const String _manifestPath = 'assets/images/sprites/manifest.json';

class RoomSprites {
  RoomSprites._({this.avatar, Map<String, FurnitureSprite>? furniture})
      : furniture = furniture ?? const {};

  final AvatarSprites? avatar;
  final Map<String, FurnitureSprite> furniture;

  bool get hasAvatar => avatar != null;
  FurnitureSprite? furnitureSprite(String key) => furniture[key];

  static RoomSprites empty() => RoomSprites._();

  /// Legge il manifest e carica i fogli via [images] (prefix Flame
  /// `assets/images/`). Non lancia mai: in errore torna [empty].
  static Future<RoomSprites> load(Images images) async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_manifestPath);
    } catch (_) {
      // Nessun manifest bundlato → grafica geometrica.
      return empty();
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      AvatarSprites? avatar;
      final furniture = <String, FurnitureSprite>{};
      for (final entry in map.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue; // salta _comment ecc.
        final cfg = value;
        try {
          switch (cfg['type'] as String?) {
            case 'avatar':
              avatar = await AvatarSprites._load(images, cfg);
            case 'furniture':
              furniture[entry.key] = await FurnitureSprite._load(images, cfg);
          }
        } catch (e) {
          // PNG mancante o frame fuori bordo → salta quell'entry, fallback.
          debugPrint('RoomSprites: skip "${entry.key}" ($e)');
        }
      }
      return RoomSprites._(avatar: avatar, furniture: furniture);
    } catch (e) {
      debugPrint('RoomSprites: manifest illeggibile ($e) → fallback');
      return empty();
    }
  }
}

/// Uno sprite mobile (frame singolo per ora) + ancora a terra.
class FurnitureSprite {
  FurnitureSprite(this.sprite, this.size, this.anchorFrac);

  final Sprite sprite;
  final Vector2 size; // px nativi del frame
  final Vector2 anchorFrac; // 0..1, punto d'appoggio a terra (default bottom-center)

  static Future<FurnitureSprite> _load(
      Images images, Map<String, dynamic> cfg) async {
    final img = await images.load(cfg['sheet'] as String);
    final sprite = Sprite(img);
    final fw = (cfg['frameW'] as num?)?.toDouble() ?? sprite.srcSize.x;
    final fh = (cfg['frameH'] as num?)?.toDouble() ?? sprite.srcSize.y;
    final a = (cfg['anchor'] as List?)?.cast<num>();
    final anchor =
        a != null ? Vector2(a[0] / fw, a[1] / fh) : Vector2(0.5, 1.0);
    return FurnitureSprite(sprite, Vector2(fw, fh), anchor);
  }
}

/// Sprite avatar animati: per azione (`idle`/`walk`…) tiene il **foglio
/// sorgente** + geometria, e ne costruisce gli sprite per (direzione, frame).
/// Sa produrre una variante **ricolorata** (felpa) con la stessa geometria.
class AvatarSprites {
  AvatarSprites._({
    required this.frameSize,
    required this.anchorFrac,
    required this.directions,
    required Map<String, _AvatarAction> actions,
    required this.dir8,
  }) : _actions = actions {
    _buildSprites();
  }

  final Vector2 frameSize;
  final Vector2 anchorFrac; // 0..1 (piedi)
  final int directions;
  final Map<String, _AvatarAction> _actions; // name -> foglio + meta
  final List<({int row, bool flip})> dir8; // 8 direzioni logiche
  final Map<String, List<List<Sprite>>> _sprites = {}; // name -> [row][frame]

  void _buildSprites() {
    _actions.forEach((name, a) {
      _sprites[name] = [
        for (var d = 0; d < directions; d++)
          [
            for (var f = 0; f < a.frames; f++)
              Sprite(a.image,
                  srcPosition:
                      Vector2(f * frameSize.x, (a.rowStart + d) * frameSize.y),
                  srcSize: frameSize),
          ],
      ];
    });
  }

  bool has(String action) => _sprites[action]?.isNotEmpty ?? false;

  /// Frame per (azione, direzione 0..7, tempo trascorso) + flag mirror.
  ({Sprite sprite, bool flip}) frame(String action, int dir, double elapsed) {
    final rows = _sprites[action]!;
    final m = dir8[dir % 8];
    final row = m.row.clamp(0, rows.length - 1);
    final frames = rows[row];
    final f = frames.length <= 1
        ? 0
        : (elapsed * _actions[action]!.fps).floor() % frames.length;
    return (sprite: frames[f], flip: m.flip);
  }

  /// Variante ricolorata (felpa/pelle). Async: rigenera le immagini una volta
  /// sola (il chiamante la mette in cache).
  Future<AvatarSprites> recolored({int? hoodie, int? skin}) async {
    final out = <String, _AvatarAction>{};
    for (final e in _actions.entries) {
      final img =
          await recolorAvatar(e.value.image, hoodie: hoodie, skin: skin);
      out[e.key] =
          _AvatarAction(img, e.value.frames, e.value.rowStart, e.value.fps);
    }
    return AvatarSprites._(
      frameSize: frameSize,
      anchorFrac: anchorFrac,
      directions: directions,
      actions: out,
      dir8: dir8,
    );
  }

  static Future<AvatarSprites> _load(
      Images images, Map<String, dynamic> cfg) async {
    final fw = (cfg['frameW'] as num).toDouble();
    final fh = (cfg['frameH'] as num).toDouble();
    final a = (cfg['anchor'] as List).cast<num>();
    final directions = (cfg['directions'] as num?)?.toInt() ?? 8;
    final defaultSheet = cfg['sheet'] as String?;

    final actions = <String, _AvatarAction>{};
    final actionsCfg = (cfg['actions'] as Map<String, dynamic>);
    for (final e in actionsCfg.entries) {
      final ac = e.value as Map<String, dynamic>;
      final img = await images.load((ac['sheet'] as String?) ?? defaultSheet!);
      final frames = (ac['frames'] as num).toInt();
      final rowStart = (ac['row'] as num?)?.toInt() ??
          (ac['rowStart'] as num?)?.toInt() ??
          0;
      final fps = (ac['fps'] as num?)?.toDouble() ?? 6;
      actions[e.key] = _AvatarAction(img, frames, rowStart, fps);
    }

    return AvatarSprites._(
      frameSize: Vector2(fw, fh),
      anchorFrac: Vector2(a[0] / fw, a[1] / fh),
      directions: directions,
      actions: actions,
      dir8: _buildDir8(cfg, directions),
    );
  }

  /// Mappa 8 direzioni logiche → (riga nel foglio, mirror orizzontale).
  /// `dirMap` esplicito nel manifest ha precedenza; altrimenti deriva da
  /// `directions` (8 = identità; 4 = righe pari + mirror per le dispari).
  static List<({int row, bool flip})> _buildDir8(
      Map<String, dynamic> cfg, int directions) {
    final explicit = cfg['dirMap'] as List?;
    if (explicit != null && explicit.length == 8) {
      return [
        for (final e in explicit)
          (row: (e[0] as num).toInt(), flip: (e[1] as num).toInt() != 0),
      ];
    }
    if (directions >= 8) {
      return [for (var d = 0; d < 8; d++) (row: d, flip: false)];
    }
    if (directions == 4) {
      return const [
        (row: 0, flip: false),
        (row: 1, flip: false),
        (row: 1, flip: false),
        (row: 2, flip: false),
        (row: 2, flip: false),
        (row: 3, flip: false),
        (row: 3, flip: false),
        (row: 0, flip: false),
      ];
    }
    return [for (var d = 0; d < 8; d++) (row: d % directions, flip: false)];
  }
}

/// Foglio sorgente di un'azione + metadati per costruirne gli sprite.
class _AvatarAction {
  _AvatarAction(this.image, this.frames, this.rowStart, this.fps);
  final ui.Image image;
  final int frames;
  final int rowStart;
  final double fps;
}
