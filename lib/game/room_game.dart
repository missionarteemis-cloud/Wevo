import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../theme.dart';

/// Game layer — slice 1-2 (vedi docs/game-layer.md).
///
/// Stanza isometrica locale: griglia NxN + un avatar che si muove a "snap"
/// sulla casella toccata. Niente backend qui: serve solo a provare il
/// rendering isometrico e il movimento prima di attaccare Firestore/RTDB.
class RoomGame extends FlameGame {
  @override
  Color backgroundColor() => WevoColors.ink;

  @override
  Future<void> onLoad() async {
    await add(IsoRoom());
  }
}

class IsoRoom extends PositionComponent
    with TapCallbacks, HasGameReference<RoomGame> {
  // ── Geometria griglia isometrica ──
  static const int cols = 7;
  static const int rows = 7;
  static const double tileW = 64;
  static const double tileH = 32;

  static const double _speed = 220; // px/s — velocità di movimento avatar

  final Vector2 _origin = Vector2.zero();

  // Avatar (in pixel = centro casella corrente)
  final Vector2 _avatarPos = Vector2.zero();
  final Vector2 _targetPos = Vector2.zero();
  int _targetCol = cols ~/ 2;
  int _targetRow = rows ~/ 2;

  // ── Paint riusabili (niente alloc per frame) ──
  final Paint _tileA = Paint()..color = WevoColors.surface;
  final Paint _tileB = Paint()..color = WevoColors.surfaceHi;
  final Paint _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = WevoColors.cyan.withOpacity(0.16);
  final Paint _highlight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = WevoColors.teal.withOpacity(0.7);
  final Paint _avatarGlow = Paint()
    ..color = WevoColors.pink.withOpacity(0.22);
  final Paint _avatarHalo = Paint()
    ..color = WevoColors.pink.withOpacity(0.5)
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
    // Tieni l'avatar agganciato alla sua casella dopo un resize.
    _targetPos.setFrom(_tileCenter(_targetCol, _targetRow));
    _avatarPos.setFrom(_targetPos);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  // ── Math isometrica ──
  Vector2 _rawTile(double c, double r) =>
      Vector2((c - r) * tileW / 2, (c + r) * tileH / 2);

  Vector2 _tileCenter(int c, int r) =>
      _origin + _rawTile(c.toDouble(), r.toDouble());

  void _recomputeOrigin() {
    // Centra la griglia: la casella centrale finisce a ~42% dell'altezza.
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
    return (
      c.round().clamp(0, cols - 1),
      r.round().clamp(0, rows - 1),
    );
  }

  // ── Input ──
  @override
  void onTapDown(TapDownEvent event) {
    final (col, row) = _pixelToTile(event.localPosition);
    _targetCol = col;
    _targetRow = row;
    _targetPos.setFrom(_tileCenter(col, row));
  }

  // ── Movimento (snap con interpolazione) ──
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
    _renderAvatar(canvas);
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

  void _renderAvatar(Canvas canvas) {
    final p = Offset(_avatarPos.x, _avatarPos.y);
    // Ombra/glow a terra
    canvas.drawOval(
      Rect.fromCenter(center: p, width: tileW * 0.6, height: tileH * 0.55),
      _avatarGlow,
    );
    // Alone neon dietro il corpo
    canvas.drawCircle(p.translate(0, -16), 16, _avatarHalo);
    // Corpo (capsula)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p.translate(0, -16), width: 16, height: 30),
        const Radius.circular(8),
      ),
      _avatarBody,
    );
    // Testa
    canvas.drawCircle(p.translate(0, -33), 8, _avatarHead);
  }
}
