import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' as painting;

import '../models/avatar_figure.dart';
import '../models/room_model.dart';
import '../services/presence_service.dart';
import '../theme.dart';
import 'furniture_catalog.dart';
import 'sprite_assets.dart';

/// Game layer — stanza isometrica (vedi docs/game-layer.md).
///
/// Arredo reale (Firestore via RoomService), rendering multi-cella con depth
/// sorting, selezione per silhouette, pathfinding (aggira gli ostacoli) e
/// modalità **Sposta/Ruota** con anteprima "fantasma" + conferma.
class RoomGame extends FlameGame {
  /// Item selezionato (riquadro descrizione in RoomScreen).
  final ValueNotifier<RoomFurnitureItem?> selected = ValueNotifier(null);

  /// True mentre si sta spostando un mobile (modalità fantasma).
  final ValueNotifier<bool> moving = ValueNotifier(false);

  /// Callback per persistere l'arredo (RoomScreen → RoomService.saveFurniture).
  void Function(List<RoomFurnitureItem>)? onPersist;

  /// Callback al confermare un piazzamento dall'inventario (→ Cloud Function placeItem).
  void Function(RoomFurnitureItem)? onPlace;

  /// Callback quando il mio avatar cambia cella (→ RoomScreen aggiorna roomPresence).
  void Function(int x, int y)? onMyMove;

  List<RoomFurnitureItem> _pending = const [];
  List<RoomVisitor> _pendingVisitors = const [];
  AvatarFigure _myFigure = AvatarFigure.standard;
  String _myUid = '';
  List<RoomMessage> _pendingChat = const [];
  IsoRoom? _iso;

  @override
  Color backgroundColor() => WevoColors.ink;

  @override
  Future<void> onLoad() async {
    _iso = IsoRoom(
      selected: selected,
      moving: moving,
      onPersist: (f) => onPersist?.call(f),
      onPlace: (item) => onPlace?.call(item),
      onMyMove: (x, y) => onMyMove?.call(x, y),
    );
    await add(_iso!);
    _iso!.setMyUid(_myUid);
    _iso!.setFurniture(_pending);
    _iso!.setVisitors(_pendingVisitors);
    _iso!.setMyFigure(_myFigure);
    _iso!.setChat(_pendingChat);
  }

  /// Aspetto del mio avatar (recolor felpa, ecc.).
  void setMyFigure(AvatarFigure figure) {
    _myFigure = figure;
    _iso?.setMyFigure(figure);
  }

  /// Il mio uid (per attribuire i messaggi al mio avatar).
  void setMyUid(String uid) {
    _myUid = uid;
    _iso?.setMyUid(uid);
  }

  /// Cronologia chat live (da RoomScreen → PresenceService.roomChatStream).
  void setChat(List<RoomMessage> messages) {
    _pendingChat = messages;
    _iso?.setChat(messages);
  }

  /// Sto scrivendo io (nuvoletta "..." sopra il mio avatar).
  void setMyTyping(bool typing) => _iso?.setMyTyping(typing);

  void applyRoom(RoomModel room) {
    _pending = room.furniture;
    _iso?.setFurniture(room.furniture);
  }

  /// Altri visitatori live nella stanza (da RoomScreen → PresenceService).
  void setVisitors(List<RoomVisitor> visitors) {
    _pendingVisitors = visitors;
    _iso?.setVisitors(visitors);
  }

  void startMove() => _iso?.startMove();
  void rotateSelected() => _iso?.rotate();
  void cancelMove() => _iso?.cancelMove();

  /// Avvia il piazzamento di un item posseduto (dall'inventario).
  void startPlace(RoomFurnitureItem item) => _iso?.startPlace(item);
}

/// Geometria del box isometrico di un mobile.
typedef _BoxPoints = ({
  Offset topC,
  Offset rightC,
  Offset bottomC,
  Offset leftC,
  Offset t2,
  Offset r2,
  Offset b2,
  Offset l2,
});

class IsoRoom extends PositionComponent
    with TapCallbacks, HasGameReference<RoomGame> {
  IsoRoom({
    required this.selected,
    required this.moving,
    required this.onPersist,
    required this.onPlace,
    required this.onMyMove,
  });

  final ValueNotifier<RoomFurnitureItem?> selected;
  final ValueNotifier<bool> moving;
  final void Function(List<RoomFurnitureItem>) onPersist;
  final void Function(RoomFurnitureItem) onPlace;
  final void Function(int x, int y) onMyMove;

  // ── Geometria griglia ──
  static const int cols = 7;
  static const int rows = 7;
  static const double tileW = 64;
  static const double tileH = 32;
  static const double _speed = 130; // px/s (movimento più calmo)
  static const double _visitorLerp = 9.0; // velocità di interpolazione visitatori

  final Vector2 _origin = Vector2.zero();

  // Avatar
  int _avatarCol = cols ~/ 2;
  int _avatarRow = rows ~/ 2;
  final Vector2 _avatarPos = Vector2.zero();
  List<(int, int)> _path = const [];
  int _destCol = cols ~/ 2;
  int _destRow = rows ~/ 2;

  // Arredo + collisione
  List<RoomFurnitureItem> _furniture = const [];
  final Set<int> _occupied = <int>{};

  // Altri visitatori live (multiplayer) + posizione interpolata (anti-scatti)
  List<RoomVisitor> _visitors = const [];
  final Map<String, Vector2> _visitorPos = {};
  void setVisitors(List<RoomVisitor> v) {
    _visitors = v;
    final ids = v.map((e) => e.uid).toSet();
    _visitorPos.removeWhere((uid, _) => !ids.contains(uid));
    _visitorFacing.removeWhere((uid, _) => !ids.contains(uid));
    _visitorWalking.removeWhere((uid, _) => !ids.contains(uid));
  }

  // Anteprima spostamento/piazzamento (null = nessun fantasma attivo)
  RoomFurnitureItem? _ghost;
  bool _ghostIsNew = false; // true = piazzamento da inventario (non ancora in stanza)

  // ── Paint ──
  final Paint _tileA = Paint()..color = WevoColors.surface;
  final Paint _tileB = Paint()..color = WevoColors.surfaceHi;
  final Paint _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0x2962E6FF);
  final Paint _highlight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xB36DD7D7);
  final Paint _furnEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0x40FFFFFF);
  final Paint _selEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = WevoColors.gold;
  final Paint _avatarGlow = Paint()..color = const Color(0x38FA61A6);
  final Paint _avatarHalo = Paint()
    ..color = const Color(0x80FA61A6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _avatarBody = Paint()..color = WevoColors.pink;
  final Paint _avatarHead = Paint()..color = WevoColors.teal;
  // Visitatori (multiplayer) — colore distinto dal mio avatar.
  final Paint _visitorGlow = Paint()..color = const Color(0x33A4A8F3);
  final Paint _visitorHalo = Paint()
    ..color = const Color(0x66A4A8F3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _visitorBody = Paint()..color = WevoColors.periwinkle;
  final Paint _visitorHead = Paint()..color = WevoColors.lightBlue;

  // ── Sprite pixel-art (fallback geometrico finché i PNG non esistono) ──
  RoomSprites _sprites = RoomSprites.empty();
  int _facing = 2; // direzione logica avatar (0..7)
  double _animT = 0; // clock animazione (s), condiviso avatar/visitatori
  bool _walking = false;
  final Map<String, int> _visitorFacing = {};
  final Map<String, bool> _visitorWalking = {};

  // Aspetto: skin per (base, felpa, pelle, capelli) in cache.
  String _myBase = 'avatar_base';
  (int?, int?, int?) _myColors = (null, null, null); // (hoodie, skin, hair)
  final Map<(String, int?, int?, int?), AvatarSprites> _skinCache = {};
  final Set<(String, int?, int?, int?)> _skinBuilding = {};

  void setMyFigure(AvatarFigure figure) {
    _myBase = figure.base;
    _myColors = (figure.hoodie, figure.skin, figure.hair);
    _skinFor(_myBase, _myColors); // pre-costruisce (best-effort)
  }

  /// Skin per (base, felpa, pelle, capelli): base se nessun recolor/non pronta.
  AvatarSprites? _skinFor(String base, (int?, int?, int?) colors) {
    final baseSprites = _sprites.avatarFor(base);
    if (baseSprites == null ||
        (colors.$1 == null && colors.$2 == null && colors.$3 == null)) {
      return baseSprites;
    }
    final key = (base, colors.$1, colors.$2, colors.$3);
    final cached = _skinCache[key];
    if (cached != null) return cached;
    if (!_skinBuilding.contains(key)) {
      _skinBuilding.add(key);
      baseSprites
          .recolored(hoodie: colors.$1, skin: colors.$2, hair: colors.$3)
          .then((s) {
        _skinCache[key] = s;
        _skinBuilding.remove(key);
      });
    }
    return baseSprites; // base finché la variante ricolorata non è pronta
  }

  // ── Chat stanza (nuvolette in-world) ──
  static const double _bubbleLife = 18; // s di vita di una nuvoletta
  static const double _bubbleDrift = 9; // px/s di salita
  String _myUid = '';
  bool _myTyping = false;
  final List<_Bubble> _bubbles = [];
  final Set<String> _seenMsgIds = {};
  bool _chatSeeded = false;

  void setMyUid(String uid) => _myUid = uid;
  void setMyTyping(bool typing) => _myTyping = typing;

  /// Nuove nuvolette dai messaggi arrivati (il primo batch è solo "storia").
  void setChat(List<RoomMessage> messages) {
    if (!_chatSeeded) {
      for (final m in messages) {
        _seenMsgIds.add(m.id);
      }
      _chatSeeded = true;
      return;
    }
    for (final m in messages) {
      if (_seenMsgIds.add(m.id)) {
        _bubbles.add(_Bubble(m.senderId, m.name, m.text));
      }
    }
    if (_bubbles.length > 40) {
      _bubbles.removeRange(0, _bubbles.length - 40);
    }
  }

  @override
  Future<void> onLoad() async {
    size = game.size;
    _recomputeOrigin();
    _syncAvatarPixel();
    _sprites = await RoomSprites.load(game.images); // best-effort, mai lancia
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    _recomputeOrigin();
    _syncAvatarPixel();
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  void _syncAvatarPixel() =>
      _avatarPos.setFrom(_tileCenter(_avatarCol, _avatarRow));

  // ── Arredo / collisione ──
  void setFurniture(List<RoomFurnitureItem> items) {
    _furniture = items;
    _recomputeOccupied();
    _ensureAvatarOffFurniture();
  }

  void _recomputeOccupied() {
    _occupied.clear();
    for (final item in _furniture) {
      for (final (c, r) in _footprintTiles(item)) {
        _occupied.add(_key(c, r));
      }
    }
  }

  Iterable<(int, int)> _footprintTiles(RoomFurnitureItem item) sync* {
    final (w, h) = footprintWH(furnitureDef(item.itemId), item.rot);
    for (var dy = 0; dy < h; dy++) {
      for (var dx = 0; dx < w; dx++) {
        yield (item.x + dx, item.y + dy);
      }
    }
  }

  int _key(int c, int r) => r * cols + c;
  bool _inBounds(int c, int r) => c >= 0 && c < cols && r >= 0 && r < rows;
  bool _isOccupied(int c, int r) => _occupied.contains(_key(c, r));

  void _ensureAvatarOffFurniture() {
    if (!_isOccupied(_avatarCol, _avatarRow)) return;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!_isOccupied(c, r)) {
          _avatarCol = c;
          _avatarRow = r;
          _destCol = c;
          _destRow = r;
          _path = const [];
          _syncAvatarPixel();
          return;
        }
      }
    }
  }

  // ── Math isometrica ──
  Vector2 _rawTile(double c, double r) =>
      Vector2((c - r) * tileW / 2, (c + r) * tileH / 2);

  Vector2 _tileCenter(int c, int r) =>
      _origin + _rawTile(c.toDouble(), r.toDouble());

  void _recomputeOrigin() {
    final centerRaw = _rawTile((cols - 1) / 2, (rows - 1) / 2);
    _origin
      ..x = size.x / 2 - centerRaw.x
      ..y = size.y * 0.42 - centerRaw.y;
  }

  (int, int) _pixelToTile(Vector2 p) {
    final dx = p.x - _origin.x;
    final dy = p.y - _origin.y;
    final c = (dx / (tileW / 2) + dy / (tileH / 2)) / 2;
    final r = (dy / (tileH / 2) - dx / (tileW / 2)) / 2;
    return (c.round().clamp(0, cols - 1), r.round().clamp(0, rows - 1));
  }

  // ── Box geometry / hit-test ──
  _BoxPoints _boxPoints(RoomFurnitureItem item) {
    final def = furnitureDef(item.itemId);
    final (w, h) = footprintWH(def, item.rot);
    final ph = def.height;
    final back = _tileCenter(item.x, item.y);
    final rightT = _tileCenter(item.x + w - 1, item.y);
    final frontT = _tileCenter(item.x + w - 1, item.y + h - 1);
    final leftT = _tileCenter(item.x, item.y + h - 1);
    final topC = Offset(back.x, back.y - tileH / 2);
    final rightC = Offset(rightT.x + tileW / 2, rightT.y);
    final bottomC = Offset(frontT.x, frontT.y + tileH / 2);
    final leftC = Offset(leftT.x - tileW / 2, leftT.y);
    return (
      topC: topC,
      rightC: rightC,
      bottomC: bottomC,
      leftC: leftC,
      t2: topC.translate(0, -ph),
      r2: rightC.translate(0, -ph),
      b2: bottomC.translate(0, -ph),
      l2: leftC.translate(0, -ph),
    );
  }

  List<Offset> _silhouette(RoomFurnitureItem item) {
    final g = _boxPoints(item);
    return [g.leftC, g.bottomC, g.rightC, g.r2, g.t2, g.l2];
  }

  bool _pointInPoly(Offset p, List<Offset> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i];
      final b = poly[j];
      if (((a.dy > p.dy) != (b.dy > p.dy)) &&
          (p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  RoomFurnitureItem? _furnitureAtPixel(Vector2 p) {
    final pt = Offset(p.x, p.y);
    final sorted = [..._furniture]
      ..sort((a, b) => _furnitureBaseY(b).compareTo(_furnitureBaseY(a)));
    for (final item in sorted) {
      if (_pointInPoly(pt, _silhouette(item))) return item;
    }
    return null;
  }

  // ── Pathfinding (BFS) ──
  List<(int, int)> _findPath(int sc, int sr, int gc, int gr) {
    if (sc == gc && sr == gr) return const [];
    final prev = <int, int>{};
    final visited = <int>{_key(sc, sr)};
    final queue = <(int, int)>[(sc, sr)];
    const dirs = [
      (1, 0), (-1, 0), (0, 1), (0, -1), // ortogonali
      (1, 1), (1, -1), (-1, 1), (-1, -1), // diagonali
    ];
    var found = false;
    while (queue.isNotEmpty) {
      final (cc, cr) = queue.removeAt(0);
      if (cc == gc && cr == gr) {
        found = true;
        break;
      }
      for (final (dc, dr) in dirs) {
        final nc = cc + dc;
        final nr = cr + dr;
        if (!_inBounds(nc, nr)) continue;
        final k = _key(nc, nr);
        if (visited.contains(k)) continue;
        if (_isOccupied(nc, nr)) continue;
        visited.add(k);
        prev[k] = _key(cc, cr);
        queue.add((nc, nr));
      }
    }
    if (!found) return const [];
    final path = <(int, int)>[];
    var k = _key(gc, gr);
    final startK = _key(sc, sr);
    while (k != startK) {
      path.add((k % cols, k ~/ cols));
      k = prev[k]!;
    }
    return path.reversed.toList();
  }

  // ── Spostamento / rotazione ──
  void startMove() {
    final s = selected.value;
    if (s == null) return;
    _ghost = s;
    _ghostIsNew = false;
    moving.value = true;
  }

  void cancelMove() {
    _ghost = null;
    _ghostIsNew = false;
    moving.value = false;
  }

  /// Piazzamento di un item posseduto (dall'inventario): fantasma su cella libera.
  void startPlace(RoomFurnitureItem item) {
    _ghost = _firstFreePlacement(item);
    _ghostIsNew = true;
    selected.value = null;
    moving.value = true;
  }

  RoomFurnitureItem _firstFreePlacement(RoomFurnitureItem item) {
    final center = _clampToBounds(item.copyWith(x: cols ~/ 2, y: rows ~/ 2));
    if (_isPlacementValid(center, '')) return center;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cand = _clampToBounds(item.copyWith(x: c, y: r));
        if (_isPlacementValid(cand, '')) return cand;
      }
    }
    return _clampToBounds(item.copyWith(x: 0, y: 0));
  }

  void rotate() {
    if (_ghost != null) {
      _ghost = _clampToBounds(_ghost!.copyWith(rot: (_ghost!.rot + 90) % 360));
      return;
    }
    final s = selected.value;
    if (s == null) return;
    final rotated = _clampToBounds(s.copyWith(rot: (s.rot + 90) % 360));
    if (_isPlacementValid(rotated, s.instanceId)) {
      _replace(rotated);
      selected.value = rotated;
      onPersist(_furniture);
    }
  }

  RoomFurnitureItem _clampToBounds(RoomFurnitureItem item) {
    final (w, h) = footprintWH(furnitureDef(item.itemId), item.rot);
    return item.copyWith(
      x: item.x.clamp(0, cols - w),
      y: item.y.clamp(0, rows - h),
    );
  }

  bool _isPlacementValid(RoomFurnitureItem item, String excludeId) {
    for (final (c, r) in _footprintTiles(item)) {
      if (!_inBounds(c, r)) return false;
    }
    final others = <int>{};
    for (final f in _furniture) {
      if (f.instanceId == excludeId) continue;
      for (final (c, r) in _footprintTiles(f)) {
        others.add(_key(c, r));
      }
    }
    for (final (c, r) in _footprintTiles(item)) {
      if (others.contains(_key(c, r))) return false;
    }
    return true;
  }

  void _replace(RoomFurnitureItem item) {
    _furniture = [
      for (final f in _furniture)
        if (f.instanceId == item.instanceId) item else f,
    ];
    _recomputeOccupied();
  }

  // ── Input ──
  @override
  void onTapDown(TapDownEvent event) {
    final local = event.localPosition;

    // Modalità sposta: il tocco riposiziona/conferma il fantasma.
    if (_ghost != null) {
      final (col, row) = _pixelToTile(local);
      final (w, h) = footprintWH(furnitureDef(_ghost!.itemId), _ghost!.rot);
      final nx = col.clamp(0, cols - w);
      final ny = row.clamp(0, rows - h);
      if (nx == _ghost!.x && ny == _ghost!.y) {
        if (_isPlacementValid(_ghost!, _ghost!.instanceId)) {
          if (_ghostIsNew) {
            // Piazzamento da inventario → Cloud Function placeItem (RoomScreen).
            onPlace(_ghost!);
            selected.value = null;
          } else {
            // Riposizionamento di un mobile già in stanza → salva diretto.
            _replace(_ghost!);
            selected.value = _ghost;
            onPersist(_furniture);
          }
          _ghost = null;
          _ghostIsNew = false;
          moving.value = false;
        }
      } else {
        _ghost = _ghost!.copyWith(x: nx, y: ny);
      }
      return;
    }

    // Normale: silhouette = seleziona; pavimento = pathfind.
    final hit = _furnitureAtPixel(local);
    if (hit != null) {
      selected.value = hit;
      return;
    }
    final (col, row) = _pixelToTile(local);
    if (_isOccupied(col, row)) return;
    selected.value = null;
    _destCol = col;
    _destRow = row;
    _path = _findPath(_avatarCol, _avatarRow, col, row);
  }

  // ── Movimento ──
  @override
  void update(double dt) {
    super.update(dt);
    _animT += dt;
    for (final b in _bubbles) {
      b.age += dt;
    }
    _bubbles.removeWhere((b) => b.age > _bubbleLife);
    _updateVisitors(dt);

    if (_path.isEmpty) {
      _walking = false;
      return;
    }
    _walking = true;
    final (nc, nr) = _path.first;
    _facing = _dir8(nc - _avatarCol, nr - _avatarRow); // direzione del prossimo passo
    final dest = _tileCenter(nc, nr);
    final delta = dest - _avatarPos;
    final dist = delta.length;
    final step = _speed * dt;
    if (step >= dist) {
      _avatarPos.setFrom(dest);
      _avatarCol = nc;
      _avatarRow = nr;
      _path = _path.sublist(1);
      onMyMove(_avatarCol, _avatarRow); // aggiorna la mia posizione live
    } else {
      _avatarPos.add(delta.normalized() * step);
    }
  }

  /// (dc,dr) ∈ {-1,0,1}² → direzione logica 0..7 (orario in spazio griglia).
  int _dir8(int dc, int dr) {
    final c = dc.sign;
    final r = dr.sign;
    return switch ((c, r)) {
      (1, 0) => 0,
      (1, 1) => 1,
      (0, 1) => 2,
      (-1, 1) => 3,
      (-1, 0) => 4,
      (-1, -1) => 5,
      (0, -1) => 6,
      (1, -1) => 7,
      _ => _facing,
    };
  }

  /// Interpola le posizioni dei visitatori verso la loro cella target
  /// (anti-scatti: gli update RTDB sono discreti, qui si smussa lato client).
  void _updateVisitors(double dt) {
    final t = (_visitorLerp * dt).clamp(0.0, 1.0);
    for (final v in _visitors) {
      final target = _tileCenter(v.x.clamp(0, cols - 1), v.y.clamp(0, rows - 1));
      final cur = _visitorPos[v.uid];
      if (cur == null) {
        _visitorPos[v.uid] = target.clone();
        _visitorWalking[v.uid] = false;
      } else {
        final delta = target - cur;
        final moving = delta.length > 1.5;
        _visitorWalking[v.uid] = moving;
        if (moving) _visitorFacing[v.uid] = _dir8FromScreen(delta);
        cur.add(delta * t);
      }
    }
  }

  /// Delta in pixel-schermo → direzione logica (per i visitatori interpolati).
  int _dir8FromScreen(Vector2 d) {
    final c = d.x / (tileW / 2) + d.y / (tileH / 2);
    final r = d.y / (tileH / 2) - d.x / (tileW / 2);
    int z(double v) => v.abs() < 0.01 ? 0 : (v < 0 ? -1 : 1);
    return _dir8(z(c), z(r));
  }

  // ── Render ──
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderFloor(canvas);
    _renderHighlight(canvas);
    _renderObjects(canvas);
    if (_ghost != null) _drawGhost(canvas);
    _renderChat(canvas);
  }

  // ── Render chat (nuvolette sopra la testa) ──
  void _renderChat(Canvas canvas) {
    _drawActorChat(canvas, _avatarPos, _myUid, _myTyping);
    for (final v in _visitors) {
      _drawActorChat(canvas, _visitorRenderPos(v), v.uid, v.typing);
    }
  }

  void _drawActorChat(Canvas canvas, Vector2 pos, String uid, bool typing) {
    if (uid.isEmpty) return;
    final headTop = pos.y - 52; // sopra la testa
    final cx = pos.x;
    if (typing) _drawTypingBubble(canvas, cx, headTop);
    final lift = typing ? 22.0 : 0.0;
    for (final b in _bubbles) {
      if (b.senderId != uid) continue;
      final y = headTop - lift - b.age * _bubbleDrift;
      _drawBubble(canvas, cx, y, b.name, b.text, _bubbleOpacity(b.age),
          tail: b.age < 2.5 && !typing);
    }
  }

  double _bubbleOpacity(double age) {
    const fadeOut = _bubbleLife - 3;
    if (age <= fadeOut) return 1;
    return (1 - (age - fadeOut) / 3).clamp(0.0, 1.0);
  }

  /// Nuvoletta "Nome: testo". [yBottom] = base della nuvoletta (verso la testa).
  void _drawBubble(Canvas canvas, double cx, double yBottom, String name,
      String text, double op, {bool tail = false}) {
    if (op <= 0) return;
    final tp = painting.TextPainter(
      text: painting.TextSpan(children: [
        painting.TextSpan(
            text: '$name ',
            style: painting.TextStyle(
                color: WevoColors.teal.withValues(alpha: op),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        painting.TextSpan(
            text: text,
            style: painting.TextStyle(
                color: const Color(0xFFFFFFFF).withValues(alpha: op),
                fontSize: 11)),
      ]),
      textDirection: painting.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 150);
    const padX = 8.0, padY = 5.0;
    final w = tp.width + padX * 2;
    final h = tp.height + padY * 2;
    final rect = Rect.fromLTWH(cx - w / 2, yBottom - h, w, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(
        rr, Paint()..color = const Color(0xF01A1230).withValues(alpha: 0.94 * op));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = WevoColors.teal.withValues(alpha: 0.5 * op));
    if (tail) {
      final path = Path()
        ..moveTo(cx - 5, rect.bottom)
        ..lineTo(cx + 5, rect.bottom)
        ..lineTo(cx, rect.bottom + 6)
        ..close();
      canvas.drawPath(
          path, Paint()..color = const Color(0xF01A1230).withValues(alpha: 0.94 * op));
    }
    tp.paint(canvas, Offset(rect.left + padX, rect.top + padY));
  }

  /// Nuvoletta "..." animata mentre qualcuno scrive.
  void _drawTypingBubble(Canvas canvas, double cx, double yBottom) {
    final dots = 1 + (_animT * 2).floor() % 3; // 1..3 ciclici
    const w = 34.0, h = 20.0;
    final rect = Rect.fromLTWH(cx - w / 2, yBottom - h, w, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rr, Paint()..color = const Color(0xE61A1230));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = WevoColors.teal.withValues(alpha: 0.5));
    final dotPaint = Paint()..color = const Color(0xFFFFFFFF);
    for (var i = 0; i < 3; i++) {
      final on = i < dots;
      canvas.drawCircle(
          Offset(rect.center.dx + (i - 1) * 8, rect.center.dy),
          2.2,
          on ? dotPaint : (Paint()..color = const Color(0x55FFFFFF)));
    }
    final path = Path()
      ..moveTo(cx - 5, rect.bottom)
      ..lineTo(cx + 5, rect.bottom)
      ..lineTo(cx, rect.bottom + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xE61A1230));
  }

  Path _diamond(Vector2 c) => Path()
    ..moveTo(c.x, c.y - tileH / 2)
    ..lineTo(c.x + tileW / 2, c.y)
    ..lineTo(c.x, c.y + tileH / 2)
    ..lineTo(c.x - tileW / 2, c.y)
    ..close();

  void _renderFloor(Canvas canvas) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final path = _diamond(_tileCenter(c, r));
        canvas.drawPath(path, (c + r).isEven ? _tileA : _tileB);
        canvas.drawPath(path, _edge);
      }
    }
  }

  void _renderHighlight(Canvas canvas) {
    if (_path.isEmpty) return;
    canvas.drawPath(_diamond(_tileCenter(_destCol, _destRow)), _highlight);
  }

  void _renderObjects(Canvas canvas) {
    // 1) Mobili "piatti" (tappeti, h<=6) col pavimento: non occludono nessuno.
    final flat = _furniture
        .where((f) => furnitureDef(f.itemId).height <= 6)
        .toList()
      ..sort((a, b) => _furnitureBaseY(a).compareTo(_furnitureBaseY(b)));
    for (final f in flat) {
      _drawFurniture(canvas, f);
    }

    // 2) Mobili "alti" + personaggi: ordinati per **occlusione isometrica
    //    corretta** (separating-axis sui footprint), non per singola cella →
    //    gestisce i mobili lunghi (un personaggio davanti alla parte sinistra
    //    di un letto 3x1 non viene più coperto).
    final items = <_DepthItem>[
      for (final f in _furniture)
        if (furnitureDef(f.itemId).height > 6)
          _DepthItem(_furnRect(f), () => _drawFurniture(canvas, f)),
      for (final v in _visitors)
        _DepthItem(_tileRect(_pixelToTile(_visitorRenderPos(v))),
            () => _renderVisitor(canvas, v)),
      _DepthItem(
          _tileRect(_pixelToTile(_avatarPos)), () => _renderAvatar(canvas)),
    ];
    for (final it in _depthSorted(items)) {
      it.draw();
    }
  }

  /// Ordinamento topologico per occlusione isometrica: rispetta **tutti** i
  /// vincoli "a è dietro b" (separating-axis) — gestisce anche gli angolini tra
  /// mobili adiacenti. A parità, ordina per profondità dell'angolo frontale.
  List<_DepthItem> _depthSorted(List<_DepthItem> items) {
    final n = items.length;
    final after = List.generate(n, (_) => <int>[]); // after[i]: j dopo i
    final indeg = List<int>.filled(n, 0); // predecessori non ancora piazzati
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final iB = _behind(items[i].rect, items[j].rect);
        final jB = _behind(items[j].rect, items[i].rect);
        if (iB && !jB) {
          after[i].add(j);
          indeg[j]++;
        } else if (jB && !iB) {
          after[j].add(i);
          indeg[i]++;
        }
      }
    }
    int depth(int k) => items[k].rect.$3 + items[k].rect.$4; // xmax+ymax
    final out = <_DepthItem>[];
    final done = List<bool>.filled(n, false);
    for (var placed = 0; placed < n; placed++) {
      var best = -1;
      for (var i = 0; i < n; i++) {
        if (done[i] || indeg[i] != 0) continue;
        if (best == -1 || depth(i) < depth(best)) best = i;
      }
      if (best == -1) {
        // ciclo residuo (raro): sblocca col più indietro tra i rimasti.
        for (var i = 0; i < n; i++) {
          if (done[i]) continue;
          if (best == -1 || depth(i) < depth(best)) best = i;
        }
      }
      done[best] = true;
      out.add(items[best]);
      for (final j in after[best]) {
        indeg[j]--;
      }
    }
    return out;
  }

  (int, int, int, int) _furnRect(RoomFurnitureItem item) {
    final (w, h) = footprintWH(furnitureDef(item.itemId), item.rot);
    return (item.x, item.y, item.x + w, item.y + h); // max esclusivo
  }

  (int, int, int, int) _tileRect((int, int) t) =>
      (t.$1, t.$2, t.$1 + 1, t.$2 + 1);

  /// a "dietro" b se interamente più indietro di b su un asse della griglia
  /// (regola d'occlusione separating-axis).
  bool _behind((int, int, int, int) a, (int, int, int, int) b) =>
      a.$3 <= b.$1 || a.$4 <= b.$2; // a.xmax<=b.xmin || a.ymax<=b.ymin

  Vector2 _visitorRenderPos(RoomVisitor v) =>
      _visitorPos[v.uid] ??
      _tileCenter(v.x.clamp(0, cols - 1), v.y.clamp(0, rows - 1));

  double _furnitureBaseY(RoomFurnitureItem item) {
    final (w, h) = footprintWH(furnitureDef(item.itemId), item.rot);
    return _tileCenter(item.x + w - 1, item.y + h - 1).y + tileH / 2;
  }

  Color _darken(Color c, double amt) =>
      Color.lerp(c, const Color(0xFF000000), amt)!;

  void _drawBox(Canvas canvas, _BoxPoints g, Paint left, Paint right, Paint top) {
    canvas.drawPath(
      Path()
        ..moveTo(g.leftC.dx, g.leftC.dy)
        ..lineTo(g.bottomC.dx, g.bottomC.dy)
        ..lineTo(g.b2.dx, g.b2.dy)
        ..lineTo(g.l2.dx, g.l2.dy)
        ..close(),
      left,
    );
    canvas.drawPath(
      Path()
        ..moveTo(g.bottomC.dx, g.bottomC.dy)
        ..lineTo(g.rightC.dx, g.rightC.dy)
        ..lineTo(g.r2.dx, g.r2.dy)
        ..lineTo(g.b2.dx, g.b2.dy)
        ..close(),
      right,
    );
    canvas.drawPath(
      Path()
        ..moveTo(g.t2.dx, g.t2.dy)
        ..lineTo(g.r2.dx, g.r2.dy)
        ..lineTo(g.b2.dx, g.b2.dy)
        ..lineTo(g.l2.dx, g.l2.dy)
        ..close(),
      top,
    );
  }

  Path _topFace(_BoxPoints g) => Path()
    ..moveTo(g.t2.dx, g.t2.dy)
    ..lineTo(g.r2.dx, g.r2.dy)
    ..lineTo(g.b2.dx, g.b2.dy)
    ..lineTo(g.l2.dx, g.l2.dy)
    ..close();

  void _drawFurniture(Canvas canvas, RoomFurnitureItem item) {
    final g = _boxPoints(item);
    final isSel = selected.value?.instanceId == item.instanceId && _ghost == null;

    // Sprite pixel-art se disponibile, altrimenti box geometrico (fallback).
    final fs = _sprites.furnitureSprite(item.itemId);
    if (fs != null) {
      _blit(canvas, fs.sprite, Vector2(g.bottomC.dx, g.bottomC.dy),
          fs.anchorFrac, fs.size, false);
      if (isSel) canvas.drawPath(_topFace(g), _selEdge);
      return;
    }

    final def = furnitureDef(item.itemId);
    _drawBox(
      canvas,
      g,
      Paint()..color = _darken(def.color, 0.45),
      Paint()..color = _darken(def.color, 0.25),
      Paint()..color = def.color,
    );
    canvas.drawPath(_topFace(g), _furnEdge);
    if (isSel) canvas.drawPath(_topFace(g), _selEdge);
  }

  /// Disegna uno [sprite] con la sua ancora ([anchorFrac], 0..1) appoggiata a
  /// [point] (px schermo), a scala nativa, con eventuale mirror orizzontale.
  void _blit(Canvas canvas, Sprite sprite, Vector2 point, Vector2 anchorFrac,
      Vector2 size, bool flip) {
    canvas.save();
    canvas.translate(point.x, point.y);
    if (flip) canvas.scale(-1, 1);
    sprite.render(
      canvas,
      position: Vector2(-anchorFrac.x * size.x, -anchorFrac.y * size.y),
      size: size,
    );
    canvas.restore();
  }

  void _drawGhost(Canvas canvas) {
    final item = _ghost!;
    final valid = _isPlacementValid(item, item.instanceId);
    final tint = valid ? WevoColors.teal : WevoColors.coral;
    // celle del footprint evidenziate
    for (final (c, r) in _footprintTiles(item)) {
      canvas.drawPath(_diamond(_tileCenter(c, r)), Paint()..color = tint.withOpacity(0.18));
    }
    final g = _boxPoints(item);
    final face = Paint()..color = tint.withOpacity(0.32);
    _drawBox(canvas, g, face, face, face);
    canvas.drawPath(
      _topFace(g),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = tint,
    );
  }

  void _renderAvatar(Canvas canvas) {
    if (_blitActor(
        canvas, _skinFor(_myBase, _myColors), _avatarPos, _facing, _walking)) {
      return;
    }
    final p = Offset(_avatarPos.x, _avatarPos.y);
    canvas.drawOval(
      Rect.fromCenter(center: p, width: tileW * 0.6, height: tileH * 0.55),
      _avatarGlow,
    );
    canvas.drawCircle(p.translate(0, -16), 16, _avatarHalo);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -16), width: 16, height: 30),
        const Radius.circular(8),
      ),
      _avatarBody,
    );
    canvas.drawCircle(p.translate(0, -33), 8, _avatarHead);
  }

  /// Disegna un attore (avatar o visitatore) come sprite animato se l'arte è
  /// caricata. Torna false se non c'è sprite avatar → il chiamante fa fallback.
  bool _blitActor(Canvas canvas, AvatarSprites? skin, Vector2 footPoint,
      int facing, bool walking) {
    final av = skin;
    if (av == null) return false;
    final action = (walking && av.has('walk'))
        ? 'walk'
        : (av.has('idle') ? 'idle' : (av.has('walk') ? 'walk' : null));
    if (action == null) return false;
    final fr = av.frame(action, facing, _animT);
    _blit(canvas, fr.sprite, footPoint, av.anchorFrac, av.frameSize, fr.flip);
    return true;
  }

  /// Altro visitatore alla sua cella (colore distinto).
  void _renderVisitor(Canvas canvas, RoomVisitor v) {
    final c = _visitorRenderPos(v);
    if (_blitActor(canvas, _skinFor(v.base, (v.hoodie, v.skin, v.hair)), c,
        _visitorFacing[v.uid] ?? 2, _visitorWalking[v.uid] ?? false)) {
      return;
    }
    final p = Offset(c.x, c.y);
    canvas.drawOval(
      Rect.fromCenter(center: p, width: tileW * 0.6, height: tileH * 0.55),
      _visitorGlow,
    );
    canvas.drawCircle(p.translate(0, -16), 16, _visitorHalo);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -16), width: 16, height: 30),
        const Radius.circular(8),
      ),
      _visitorBody,
    );
    canvas.drawCircle(p.translate(0, -33), 8, _visitorHead);
  }
}

/// Una nuvoletta chat sopra un avatar (sale e sfuma con l'età).
class _Bubble {
  _Bubble(this.senderId, this.name, this.text);
  final String senderId;
  final String name;
  final String text;
  double age = 0;
}

/// Renderable ordinabile per occlusione isometrica (footprint + draw).
class _DepthItem {
  _DepthItem(this.rect, this.draw);
  final (int, int, int, int) rect; // xmin, ymin, xmax, ymax (max esclusivo)
  final void Function() draw;
}
