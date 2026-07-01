import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Ricolora regioni dell'avatar in un singolo passaggio sui pixel (base della
/// strategia "recolor-first": tante varianti da un set di sprite, **zero
/// generazioni**). Operazione una-tantum per combinazione colore (poi in cache).
///
/// - **Felpa** (`hoodie`): scala per luminanza → colori vividi e prevedibili.
/// - **Pelle** (`skin`): ricolorazione *relativa* al tono originale (`_skinSrc`).
/// - **Capelli** (`hair`): relativa a `_hairSrc` (bruno). Distinta dalla pelle:
///   la pelle ha g>b, i capelli g≈b.
///
/// Maschere per dominanza di canale (niente maschere esterne).
const _skinSrc = [223.0, 141.0, 93.0]; // tono pelle medio campionato
const _hairSrc = [120.0, 60.0, 56.0]; // bruno medio campionato

Future<ui.Image> recolorAvatar(ui.Image src,
    {int? hoodie, int? skin, int? hair}) async {
  if (hoodie == null && skin == null && hair == null) return src;
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
  // Capelli: rapporto target/origine per canale (relativo).
  double hr2 = 1, hg2 = 1, hb2 = 1;
  if (hair != null) {
    final c = ui.Color(hair);
    hr2 = (c.r * 255.0) / _hairSrc[0];
    hg2 = (c.g * 255.0) / _hairSrc[1];
    hb2 = (c.b * 255.0) / _hairSrc[2];
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
    // Pelle = caldo "morbido" (r/g moderato): esclude i rossi saturi dei capelli.
    if (skin != null &&
        r > g + 14 &&
        g > b + 10 &&
        r > 110 &&
        b < 190 &&
        r < g * 1.55) {
      px[i] = (r * sr).clamp(0.0, 255.0).toInt();
      px[i + 1] = (g * sg).clamp(0.0, 255.0).toInt();
      px[i + 2] = (b * sb).clamp(0.0, 255.0).toInt();
      continue;
    }
    // Capelli = rosso dominante e (scuri OPPURE rosso saturo): così anche il
    // riflesso caldo dei capelli segue il colore capelli, non la pelle.
    if (hair != null &&
        r > g &&
        r >= b &&
        r > 30 &&
        r < 210 &&
        (0.299 * r + 0.587 * g + 0.114 * b < 117 || r > g * 1.55)) {
      px[i] = (r * hr2).clamp(0.0, 255.0).toInt();
      px[i + 1] = (g * hg2).clamp(0.0, 255.0).toInt();
      px[i + 2] = (b * hb2).clamp(0.0, 255.0).toInt();
      continue;
    }
    // Attenua i riflessi neon magenta/rosa/viola: sul default (teal) sono voluti,
    // ma quando ricolori stonano. Solo qui (varianti ricolorate), non sul base.
    final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    if (b > g + 8 && r > g + 8 && mx - mn > 85) {
      final l = 0.299 * r + 0.587 * g + 0.114 * b;
      const k = 0.82; // quanto desaturare (0..1)
      px[i] = (r * (1 - k) + l * k).clamp(0.0, 255.0).toInt();
      px[i + 1] = (g * (1 - k) + l * k).clamp(0.0, 255.0).toInt();
      px[i + 2] = (b * (1 - k) + l * k).clamp(0.0, 255.0).toInt();
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      px, w, h, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}
