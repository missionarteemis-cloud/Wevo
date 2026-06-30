import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Ricolora la **felpa** dello sprite avatar verso [target], preservando
/// l'ombreggiatura (scala per luminanza → ombre/luci restano coerenti).
///
/// Maschera: pixel a dominanza verde-blu (la felpa teal), escludendo i
/// quasi-bianchi (scarpe) e il rosso/incarnato (pelle, capelli). È la base della
/// strategia "recolor-first": tante varianti colore da un solo set di sprite,
/// **zero generazioni**. Operazione una-tantum per colore (poi in cache).
Future<ui.Image> recolorHoodie(ui.Image src, ui.Color target) async {
  final w = src.width;
  final h = src.height;
  final data = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return src;
  final px = Uint8List.fromList(data.buffer.asUint8List());

  final tr = target.r * 255.0;
  final tg = target.g * 255.0;
  final tb = target.b * 255.0;
  // luminanza del colore target (min 1 per evitare /0)
  final tl = (0.299 * tr + 0.587 * tg + 0.114 * tb).clamp(1.0, 255.0);

  for (var i = 0; i < px.length; i += 4) {
    final r = px[i];
    final g = px[i + 1];
    final b = px[i + 2];
    final a = px[i + 3];
    if (a < 8) continue;
    // felpa = verde/blu dominanti sul rosso, e non quasi-bianco (scarpe)
    final isHoodie =
        g > r + 12 && b > r - 10 && !(r > 150 && g > 150 && b > 150);
    if (!isHoodie) continue;
    final l = 0.299 * r + 0.587 * g + 0.114 * b; // luminanza del pixel
    final s = l / tl; // aggancia la luminanza del pixel al colore target
    px[i] = (tr * s).clamp(0.0, 255.0).toInt();
    px[i + 1] = (tg * s).clamp(0.0, 255.0).toInt();
    px[i + 2] = (tb * s).clamp(0.0, 255.0).toInt();
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      px, w, h, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}
