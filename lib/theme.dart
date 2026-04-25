import 'package:flutter/material.dart';

class WevoColors {
  static const pink      = Color(0xFFCC76A1);
  static const lightBlue = Color(0xFFAFC9D8);
  static const sage      = Color(0xFFA8C3A0);
  static const dark      = Color(0xFF241623);
  static const coral     = Color(0xFFCD533B);
  static const bg        = Color(0xFFF0EDF2);
  static const cardBg    = Colors.white;
}

final WevoTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: WevoColors.dark),
  scaffoldBackgroundColor: WevoColors.bg,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: WevoColors.dark,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: WevoColors.dark,
    selectedItemColor: WevoColors.pink,
    unselectedItemColor: Colors.white54,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);
