import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Ricolora regioni dell'avatar in un singolo passaggio sui pixel (base della
/// strategia "recolor-first": tante varianti da un set di sprite, **zero
/// generazioni**). Operazione una-tantum per combinazione colore (poi in cache).
///
/// - **Felpa** (`hoodie`): scala per luminanza → colori vividi e prevedibili.
/// - **Pelle** (`skin`): ricolorazione *relativa* al tono originale (`_skinSrc`)
///   → può cambiare tinta **e** schiarirsi/scurirsi mantenendo l'ombreggiatura.
///
/// Maschere per dominanza di canale (niente maschere esterne): la felpa è
/// verde-blu dominante; la pelle è calda (r>g>b) e luminosa.
const _skinSrc = [223.0, 141.0, 93.0]; // tono pelle medio campionato dallo sprite

Future<ui.Image> recolorAvatar(ui.Image src, {int? hoodie, int? skin}) async {
  if (hoodie == null && skin == null) return src;
  final w = src.width;
  final h = src.height;
  final data = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return src;
  final px = Uint8List.fromList(data.buffer.asUint8List());

  // Felpa: rampa per luminanza verso il target.
  double hr = 0, hg = 0, hb = 0, hl = 1;
  if (hoodie != null) {
    final c = ui.Color(hoodie);
    hr = c.r * 255.0;
    hg = c.g * 255.0;
    hb = c.b * 255.0;
    hl = (0.299 * hr + 0.587 * hg + 0.114 * hb).clamp(1.0, 255.0);
  }
  // Pelle: rapporto target/origine per canale (relativo).
  double sr = 1, sg = 1, sb = 1;
  if (skin != null) {
    final c = ui.Color(skin);
    sr = (c.r * 255.0) / _skinSrc[0];
    sg = (c.g * 255.0) / _skinSrc[1];
    sb = (c.b * 255.0) / _skinSrc[2];
  }

  for (var i = 0; i < px.length; i += 4) {
    final r = px[i];
    final g = px[i + 1];
    final b = px[i + 2];
    if (px[i + 3] < 8) continue;

    if (hoodie != null &&
        g > r + 12 &&
        b > r - 10 &&
        !(r > 150 && g > 150 && b > 150)) {
      final l = 0.299 * r + 0.587 * g + 0.114 * b;
      final s = l / hl;
      px[i] = (hr * s).clamp(0.0, 255.0).toInt();
      px[i + 1] = (hg * s).clamp(0.0, 255.0).toInt();
      px[i + 2] = (hb * s).clamp(0.0, 255.0).toInt();
      continue;
    }
    if (skin != null && r > g + 14 && g > b + 10 && r > 110 && b < 190) {
      px[i] = (r * sr).clamp(0.0, 255.0).toInt();
      px[i + 1] = (g * sg).clamp(0.0, 255.0).toInt();
      px[i + 2] = (b * sb).clamp(0.0, 255.0).toInt();
      continue;
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      px, w, h, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}
