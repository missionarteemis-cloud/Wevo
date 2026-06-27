import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/room_model.dart';
import '../theme.dart';
import 'furniture_catalog.dart';

/// Game layer — stanza isometrica (vedi docs/game-layer.md).
///
/// Arredo reale (Firestore via RoomService), rendering multi-cella con
/// ordinamento per profondità, selezione oggetto a livello di **silhouette**
/// (qualunque pixel dell'oggetto), e movimento avatar con **pathfinding**
/// (aggira gli ostacoli, niente clipping).
class RoomGame extends FlameGame {
  /// Item selezionato (alimenta il riquadro descrizione in RoomScreen).
  final ValueNotifier<RoomFurnitureItem?> selected = ValueNotifier(null);

  List<RoomFurnitureItem> _pending = const [];
  IsoRoom? _iso;

  @override
  Color backgroundColor() => WevoColors.ink;

  @override
  Future<void> onLoad() async {
    _iso = IsoRoom(selected: selected);
    await add(_iso!);
    _iso!.setFurniture(_pending);
  }

  /// Aggancia la stanza reale (caricata da RoomService).
  void applyRoom(RoomModel room) {
    _pending = room.furniture;
    _iso?.setFurniture(room.furniture);
  }
}

/// Geometria del box isometrico di un mobile (corner base + corner rialzati).
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
  IsoRoom({required this.selected});

  final ValueNotifier<RoomFurnitureItem?> selected;

  // ── Geometria griglia ──
  static const int cols = 7;
  static const int rows = 7;
  static const double tileW = 64;
  static const double tileH = 32;
  static const double _speed = 220; // px/s

  final Vector2 _origin = Vector2.zero();

  // Avatar: casella logica + posizione pixel + percorso da seguire
  int _avatarCol = cols ~/ 2;
  int _avatarRow = rows ~/ 2;
  final Vector2 _avatarPos = Vector2.zero();
  List<(int, int)> _path = const [];
  int _destCol = cols ~/ 2;
  int _destRow = rows ~/ 2;

  // Arredo + celle occupate
  List<RoomFurnitureItem> _furniture = const [];
  final Set<int> _occupied = <int>{};

  // ── Paint riusabili ──
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

  @override
  Future<void> onLoad() async {
    size = game.size;
    _recomputeOrigin();
    _syncAvatarPixel();
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

  void _syncAvatarPixel() => _avatarPos.setFrom(_tileCenter(_avatarCol, _avatarRow));

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

  // ── Box geometry / hit-test silhouette ──
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

  /// Item la cui silhouette contiene il punto, front-most prima.
  RoomFurnitureItem? _furnitureAtPixel(Vector2 p) {
    final pt = Offset(p.x, p.y);
    final sorted = [..._furniture]
      ..sort((a, b) => _furnitureBaseY(b).compareTo(_furnitureBaseY(a)));
    for (final item in sorted) {
      if (_pointInPoly(pt, _silhouette(item))) return item;
    }
    return null;
  }

  // ── Pathfinding (BFS, 4-direzioni, aggira gli occupati) ──
  List<(int, int)> _findPath(int sc, int sr, int gc, int gr) {
    if (sc == gc && sr == gr) return const [];
    final prev = <int, int>{};
    final visited = <int>{_key(sc, sr)};
    final queue = <(int, int)>[(sc, sr)];
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
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

  // ── Input: silhouette oggetto = seleziona; pavimento = pathfind ──
  @override
  void onTapDown(TapDownEvent event) {
    final local = event.localPosition;
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

  // ── Movimento lungo il percorso ──
  @override
  void update(double dt) {
    super.update(dt);
    if (_path.isEmpty) return;
    final (nc, nr) = _path.first;
    final dest = _tileCenter(nc, nr);
    final delta = dest - _avatarPos;
    final dist = delta.length;
    final step = _speed * dt;
    if (step >= dist) {
      _avatarPos.setFrom(dest);
      _avatarCol = nc;
      _avatarRow = nr;
      _path = _path.sublist(1);
    } else {
      _avatarPos.add(delta.normalized() * step);
    }
  }

  // ── Render ──
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderFloor(canvas);
    _renderHighlight(canvas);
    _renderObjects(canvas);
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
    if (_path.isEmpty) return; // mostra il bersaglio solo mentre si muove
    canvas.drawPath(_diamond(_tileCenter(_destCol, _destRow)), _highlight);
  }

  void _renderObjects(Canvas canvas) {
    final renderables = <(double, void Function())>[
      for (final item in _furniture)
        (_furnitureBaseY(item), () => _drawFurniture(canvas, item)),
      (_avatarPos.y, () => _renderAvatar(canvas)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final r in renderables) {
      r.$2();
    }
  }

  double _furnitureBaseY(RoomFurnitureItem item) {
    final (w, h) = footprintWH(furnitureDef(item.itemId), item.rot);
    return _tileCenter(item.x + w - 1, item.y + h - 1).y + tileH / 2;
  }

  Color _darken(Color c, double amt) =>
      Color.lerp(c, const Color(0xFF000000), amt)!;

  void _drawFurniture(Canvas canvas, RoomFurnitureItem item) {
    final def = furnitureDef(item.itemId);
    final g = _boxPoints(item);

    // Faccia sinistra
    canvas.drawPath(
      Path()
        ..moveTo(g.leftC.dx, g.leftC.dy)
        ..lineTo(g.bottomC.dx, g.bottomC.dy)
        ..lineTo(g.b2.dx, g.b2.dy)
        ..lineTo(g.l2.dx, g.l2.dy)
        ..close(),
      Paint()..color = _darken(def.color, 0.45),
    );
    // Faccia destra
    canvas.drawPath(
      Path()
        ..moveTo(g.bottomC.dx, g.bottomC.dy)
        ..lineTo(g.rightC.dx, g.rightC.dy)
        ..lineTo(g.r2.dx, g.r2.dy)
        ..lineTo(g.b2.dx, g.b2.dy)
        ..close(),
      Paint()..color = _darken(def.color, 0.25),
    );
    // Faccia superiore
    final top = Path()
      ..moveTo(g.t2.dx, g.t2.dy)
      ..lineTo(g.r2.dx, g.r2.dy)
      ..lineTo(g.b2.dx, g.b2.dy)
      ..lineTo(g.l2.dx, g.l2.dy)
      ..close();
    canvas.drawPath(top, Paint()..color = def.color);
    canvas.drawPath(top, _furnEdge);

    if (selected.value?.instanceId == item.instanceId) {
      canvas.drawPath(top, _selEdge);
    }
  }

  void _renderAvatar(Canvas canvas) {
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
}
