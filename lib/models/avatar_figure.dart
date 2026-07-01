/// Aspetto di un avatar (vedi docs/art-spec.md / strategia "recolor-first").
///
/// Dati strutturati, persistiti su `users/{uid}.figure` e propagati ai
/// visitatori via presence. Oggi: sprite base + colore felpa (recolor in-engine,
/// gratis). Estensibile a pelle/capelli/overlay/outfit senza rompere lo schema.
class AvatarFigure {
  /// Id dello sprite set (chiave nel manifest, es. 'avatar_base').
  final String base;

  /// Colore felpa (ARGB). `null` = colore originale dello sprite (teal).
  final int? hoodie;

  /// Tono pelle (ARGB). `null` = tono originale dello sprite.
  final int? skin;

  /// Colore capelli (ARGB). `null` = colore originale. Visibile solo sulle basi
  /// con capelli scoperti (es. 'avatar_female').
  final int? hair;

  const AvatarFigure(
      {this.base = 'avatar_base', this.hoodie, this.skin, this.hair});

  static const AvatarFigure standard = AvatarFigure();

  AvatarFigure copyWith({
    String? base,
    int? hoodie,
    int? skin,
    int? hair,
    bool resetHoodie = false,
    bool resetSkin = false,
    bool resetHair = false,
  }) =>
      AvatarFigure(
        base: base ?? this.base,
        hoodie: resetHoodie ? null : (hoodie ?? this.hoodie),
        skin: resetSkin ? null : (skin ?? this.skin),
        hair: resetHair ? null : (hair ?? this.hair),
      );

  Map<String, dynamic> toMap() => {
        'base': base,
        if (hoodie != null) 'hoodie': hoodie,
        if (skin != null) 'skin': skin,
        if (hair != null) 'hair': hair,
      };

  factory AvatarFigure.fromMap(Map<String, dynamic>? m) {
    if (m == null) return standard;
    return AvatarFigure(
      base: (m['base'] as String?) ?? 'avatar_base',
      hoodie: (m['hoodie'] as num?)?.toInt(),
      skin: (m['skin'] as num?)?.toInt(),
      hair: (m['hair'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarFigure &&
      other.base == base &&
      other.hoodie == hoodie &&
      other.skin == skin &&
      other.hair == hair;

  @override
  int get hashCode => Object.hash(base, hoodie, skin, hair);
}

/// Skin base disponibili: (id nel manifest, asset miniatura per la card).
const List<(String, String)> kAvatarSkins = [
  ('avatar_base', 'assets/images/sprites/avatar_base_thumb.png'),
  ('avatar_female', 'assets/images/sprites/avatar_female_thumb.png'),
];

/// Colori felpa selezionabili (recolor in-engine). `null` = originale.
const List<int?> kHoodiePresets = [
  null, // originale (teal dello sprite)
  0xFFFF5FA2, // magenta
  0xFF9A6FD0, // viola
  0xFF62A8FF, // azzurro
  0xFF8FD46A, // verde
  0xFFFF8A3D, // arancio
  0xFFE5484D, // rosso
  0xFFFFC76A, // oro
];

/// Toni pelle selezionabili (recolor relativo). `null` = originale.
const List<int?> kSkinPresets = [
  null, // originale
  0xFFF2C8A0, // chiara
  0xFFE0A878, // media
  0xFFC98A5B, // ambra
  0xFF9B6440, // bruna
  0xFF6E4329, // scura
  0xFF4A2E1C, // molto scura
];

/// Colori capelli selezionabili (recolor relativo). `null` = originale.
const List<int?> kHairPresets = [
  null, // originale (castano)
  0xFF2B2B30, // nero
  0xFF5A3A28, // castano scuro
  0xFFE8C878, // biondo
  0xFFB5502E, // ramato
  0xFFE5484D, // rosso
  0xFFFF7FB0, // rosa
  0xFF62A8FF, // blu
  0xFFD8D8E0, // argento
];
