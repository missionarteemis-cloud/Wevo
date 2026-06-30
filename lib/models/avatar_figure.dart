import 'dart:ui' show Color;

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

  const AvatarFigure({this.base = 'avatar_base', this.hoodie});

  static const AvatarFigure standard = AvatarFigure();

  Color? get hoodieColor => hoodie == null ? null : Color(hoodie!);

  AvatarFigure copyWith({String? base, int? hoodie, bool resetHoodie = false}) =>
      AvatarFigure(
        base: base ?? this.base,
        hoodie: resetHoodie ? null : (hoodie ?? this.hoodie),
      );

  Map<String, dynamic> toMap() => {
        'base': base,
        if (hoodie != null) 'hoodie': hoodie,
      };

  factory AvatarFigure.fromMap(Map<String, dynamic>? m) {
    if (m == null) return standard;
    return AvatarFigure(
      base: (m['base'] as String?) ?? 'avatar_base',
      hoodie: (m['hoodie'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarFigure && other.base == base && other.hoodie == hoodie;

  @override
  int get hashCode => Object.hash(base, hoodie);
}

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
