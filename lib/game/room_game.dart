import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/room_model.dart';
import '../theme.dart';
import 'furniture_catalog.dart';

/// Game layer — slice game room (vedi docs/game-layer.md).
///
/// Stanza isometrica: griglia + arredo reale (da Firestore via RoomService) con
/// rendering multi-cella, ordinamento per profondità, collisione (no clipping)
/// e selezione oggetto. Movimento avatar a snap su tap.
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

class IsoRoom extends PositionComponent
    with TapCallbacks, HasGameReference<RoomGame> {
  IsoRoom({required this.selected});

  final ValueNotifier<RoomFurnitureItem?> selected;

  // ── Geometria griglia isometrica ──
  static const int cols = 7;
  static const int rows = 7;
  static const double tileW = 64;
  static const double tileH = 32;
  static const double _speed = 220; // px/s

  final Vector2 _origin = Vector2.zero();

  // Avatar (pixel = centro casella corrente)
  final Vector2 _avatarPos = Vector2.zero();
  final Vector2 _targetPos = Vector2.zero();
  int _targetCol = cols ~/ 2;
  int _targetRow = rows ~/ 2;

  // Arredo + celle occupate (collisione)
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
    _avatarPos.setFrom(_tileCenter(_targetCol, _targetRow));
    _targetPos.setFrom(_avatarPos);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    _recomputeOrigin();
    _targetPos.setFrom(_tileCenter(_targetCol, _targetRow));
    _avatarPos.setFrom(_targetPos);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

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
  bool _isOccupied(int c, int r) => _occupied.contains(_key(c, r));

  RoomFurnitureItem? _furnitureAt(int c, int r) {
    for (final item in _furniture) {
      for (final (fc, fr) in _footprintTiles(item)) {
        if (fc == c && fr == r) return item;
      }
    }
    return null;
  }

  void _ensureAvatarOffFurniture() {
    if (!_isOccupied(_targetCol, _targetRow)) return;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!_isOccupied(c, r)) {
          _targetCol = c;
          _targetRow = r;
          _targetPos.setFrom(_tileCenter(c, r));
          _avatarPos.setFrom(_targetPos);
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

  // ── Input: tocco oggetto = seleziona; tocco a vuoto = muovi ──
  @override
  void onTapDown(TapDownEvent event) {
    final (col, row) = _pixelToTile(event.localPosition);
    final item = _furnitureAt(col, row);
    if (item != null) {
      selected.value = item;
      return;
    }
    if (_isOccupied(col, row)) return; // collisione: niente movimento qui
    selected.value = null;
    _targetCol = col;
    _targetRow = row;
    _targetPos.setFrom(_tileCenter(col, row));
  }

  // ── Movimento (snap interpolato) ──
  @override
  void update(double dt) {
    super.update(dt);
    final delta = _targetPos - _avatarPos;
    final dist = delta.length;
    if (dist < 0.5) {
      _avatarPos.setFrom(_targetPos);
      return;
    }
    final step = _speed * dt;
    if (step >= dist) {
      _avatarPos.setFrom(_targetPos);
    } else {
      _avatarPos.add(delta.normalized() * step);
    }
  }

  // ── Render ──
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderFloor(canvas);
    _renderTargetHighlight(canvas);
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

  void _renderTargetHighlight(Canvas canvas) {
    canvas.drawPath(_diamond(_tileCenter(_targetCol, _targetRow)), _highlight);
  }

  /// Painter's algorithm: arredo + avatar ordinati per y della base.
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
    final (w, h) = footprintWH(def, item.rot);
    final ph = def.height;

    // Angoli esterni del rettangolo-footprint (in iso)
    final back = _tileCenter(item.x, item.y);
    final rightT = _tileCenter(item.x + w - 1, item.y);
    final frontT = _tileCenter(item.x + w - 1, item.y + h - 1);
    final leftT = _tileCenter(item.x, item.y + h - 1);
    final topC = Offset(back.x, back.y - tileH / 2);
    final rightC = Offset(rightT.x + tileW / 2, rightT.y);
    final bottomC = Offset(frontT.x, frontT.y + tileH / 2);
    final leftC = Offset(leftT.x - tileW / 2, leftT.y);
    // Angoli rialzati (faccia superiore)
    final t2 = topC.translate(0, -ph);
    final r2 = rightC.translate(0, -ph);
    final b2 = bottomC.translate(0, -ph);
    final l2 = leftC.translate(0, -ph);

    // Faccia sinistra
    canvas.drawPath(
      Path()
        ..moveTo(leftC.dx, leftC.dy)
        ..lineTo(bottomC.dx, bottomC.dy)
        ..lineTo(b2.dx, b2.dy)
        ..lineTo(l2.dx, l2.dy)
        ..close(),
      Paint()..color = _darken(def.color, 0.45),
    );
    // Faccia destra
    canvas.drawPath(
      Path()
        ..moveTo(bottomC.dx, bottomC.dy)
        ..lineTo(rightC.dx, rightC.dy)
        ..lineTo(r2.dx, r2.dy)
        ..lineTo(b2.dx, b2.dy)
        ..close(),
      Paint()..color = _darken(def.color, 0.25),
    );
    // Faccia superiore
    final top = Path()
      ..moveTo(t2.dx, t2.dy)
      ..lineTo(r2.dx, r2.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(l2.dx, l2.dy)
      ..close();
    canvas.drawPath(top, Paint()..color = def.color);
    canvas.drawPath(top, _furnEdge);

    // Bordo selezione
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
