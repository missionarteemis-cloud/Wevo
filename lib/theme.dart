import 'package:flutter/material.dart';

class WevoColors {
  static const pink = Color(0xFFFF5FA2);
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
  static const textMuted = Color(0xFFA7A1BC);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, hotPink],
  );
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
  fontFamily: 'Roboto',
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
