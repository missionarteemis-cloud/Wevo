import 'package:flutter/material.dart';

/// Tokens brand Wevo — palette unificata.
/// I vecchi nomi (hotPink, lightBlue…) sono mantenuti per backward compat.
class WevoColors {
  // ── Nuovo brand palette ──
  static const pink = Color(0xFFFA61A6);
  static const periwinkle = Color(0xFFA4A8F3);
  static const teal = Color(0xFF6DD7D7);

  // ── Token layout ──
  static const ink = Color(0xFF0E0718);
  static const surface = Color(0xFF1C1530);
  static const surfaceHi = Color(0xFF251C3D);
  static const textHi = Color(0xFFE4E0EF);
  static const textMid = Color(0xFFA7A1BC);
  static const textMuted = Color(0xFFA7A1BC);

  // ── Vecchi alias / layout colors (non toccare — bg, darkSoft, panel usati ovunque) ──
  static const hotPink = Color(0xFFFF3E8D);
  static const lightBlue = Color(0xFF8EC5FF);
  static const cyan = Color(0xFF62E6FF);
  static const sage = Color(0xFF9EDFA6);
  static const gold = Color(0xFFFFC76A);
  static const coral = Color(0xFFFF7D7D);
  static const dark = Color(0xFF12091F);
  static const darkSoft = Color(0xFF1A102B);
  static const panel = Color(0xFF201233);
  static const bg = Color(0xFF0E0718);
  static const cardBg = Color(0xFF1A1128);

  /// Il gradiente brand unico. Usalo per azioni primarie.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, periwinkle, teal],
    stops: [0.0, 0.52, 1.0],
  );

  /// Vecchio alias per compat.
  static LinearGradient get primaryGradient => brand;
}

BoxShadow wevoGlow(Color color, {double blur = 22, double spread = 1}) {
  return BoxShadow(
    color: color.withOpacity(0.35),
    blurRadius: blur,
    spreadRadius: spread,
  );
}

final WevoTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: WevoColors.pink,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: WevoColors.bg,
  fontFamily: 'Plus Jakarta Sans',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: WevoColors.darkSoft,
    selectedItemColor: WevoColors.pink,
    unselectedItemColor: Colors.white54,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
